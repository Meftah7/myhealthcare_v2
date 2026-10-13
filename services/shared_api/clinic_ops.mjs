// Shared-mode appointments, secure messaging and desk billing.
//
// Same rules as the rest of the shared API: the server re-authorizes every
// call, writes are versioned or idempotent (retry keys), conflicts are 409s
// and nothing pretends to have happened. Payments are desk records only —
// no card gateway is connected, so no money moves through this server.
import { ApiError, fields, id, requireThat, text } from './store.mjs';

const clinicianJobs = ['doctor', 'dentist'];
const deskJobs = ['receptionist'];
const maxVisitMs = 2 * 60 * 60 * 1000;

function instant(value) {
  requireThat(typeof value === 'string' && Number.isFinite(Date.parse(value)), 400, 'Invalid time.');
  return Date.parse(value);
}
function isDesk(actor) { return actor.role === 'admin' || (actor.role === 'staff' && deskJobs.includes(actor.job)); }
function safeAppointment(a) {
  return { id: a.id, patientId: a.patient, staffId: a.staff, start: new Date(a.start).toISOString(),
    end: new Date(a.end).toISOString(), status: a.status, reason: a.reason, version: a.version,
    visitType: a.visit_type, bookedAt: new Date(a.booked_at ?? a.start).toISOString(),
    checkedInAt: a.checked_in ? new Date(a.checked_in).toISOString() : null };
}
function safeInvoice(i) {
  return { id: i.id, patientId: i.patient, description: i.description, amountFils: i.amount_fils,
    paidFils: i.paid_fils, status: i.status, created: new Date(i.created).toISOString(), version: i.version };
}

/** Returns a result for a handled route, or `undefined` to fall through. */
export function clinicOps({ store, now, path, method, url, body, actor }) {
  // ---- appointments -------------------------------------------------------
  if (path === '/api/appointments' && method === 'GET') {
    const patientId = url.searchParams.get('patientId');
    if (patientId) {
      // Desk and admin see booking details (administrative), never charts.
      if (!isDesk(actor)) store.patientAccess(actor, text(patientId, 128));
      else requireThat(store.get("SELECT 1 FROM users WHERE id=? AND role='patient'", patientId), 404, 'Patient unavailable.');
      return store.all('SELECT * FROM appointments WHERE patient=? ORDER BY start DESC', patientId).map(safeAppointment);
    }
    if (actor.role === 'patient') {
      return store.all('SELECT * FROM appointments WHERE patient=? ORDER BY start DESC', actor.id).map(safeAppointment);
    }
    if (isDesk(actor)) {
      const from = url.searchParams.get('from') ? instant(url.searchParams.get('from')) : now() - 86400000;
      const to = url.searchParams.get('to') ? instant(url.searchParams.get('to')) : from + 2 * 86400000;
      requireThat(to > from && to - from <= 62 * 86400000, 400, 'Choose a range of up to 62 days.');
      return store.all('SELECT * FROM appointments WHERE start>=? AND start<? ORDER BY start', from, to).map(safeAppointment);
    }
    requireThat(actor.role === 'staff', 403);
    return store.all('SELECT * FROM appointments WHERE staff=? ORDER BY start', actor.id).map(safeAppointment);
  }
  if (path === '/api/appointments' && method === 'POST') {
    fields(body, ['patientId', 'staffId', 'start', 'end', 'reason', 'visitType', 'idempotencyKey']);
    const visitType = body.visitType ?? 'followUp';
    requireThat(typeof visitType === 'string' && /^[a-zA-Z]{1,40}$/.test(visitType), 400, 'Invalid visit type.');
    const patientId = text(body.patientId, 128), staffId = text(body.staffId, 128);
    requireThat(actor.role === 'patient' ? actor.id === patientId : isDesk(actor), 403, 'You cannot book for this patient.');
    requireThat(store.get("SELECT 1 FROM users WHERE id=? AND role='patient' AND active=1", patientId), 404, 'Patient unavailable.');
    const clinician = store.get("SELECT * FROM users WHERE id=? AND role='staff' AND active=1", staffId);
    requireThat(clinician && clinicianJobs.includes(clinician.job), 400, 'Choose an active doctor or dentist.');
    const start = instant(body.start), end = instant(body.end);
    requireThat(end > start && end - start <= maxVisitMs, 400, 'Choose a visit of up to two hours.');
    requireThat(start > now(), 400, 'Choose a future time.');
    const reason = body.reason == null ? null : text(body.reason, 500);
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      // Checked inside the transaction so two bookings cannot both pass.
      const clash = store.get("SELECT 1 FROM appointments WHERE staff=? AND status!='cancelled' AND start<? AND end>?", staffId, end, start);
      requireThat(!clash, 409, 'That time was just taken. Choose another time.');
      const appointmentId = id();
      store.run('INSERT INTO appointments(id,patient,staff,start,end,reason,booked_by,visit_type,booked_at) VALUES(?,?,?,?,?,?,?,?,?)',
        appointmentId, patientId, staffId, start, end, reason, actor.id, visitType, now());
      // A booked visit is a care relationship, as in the local app.
      store.run('INSERT OR IGNORE INTO care VALUES(?,?)', patientId, staffId);
      store.audit(actor.id, actor.id === patientId ? 'appointment.booked' : 'desk.appointment.booked', appointmentId);
      return safeAppointment(store.get('SELECT * FROM appointments WHERE id=?', appointmentId));
    }));
  }
  const single = /^\/api\/appointments\/([^/]+)$/.exec(path);
  if (single && method === 'GET') {
    const a = store.get('SELECT * FROM appointments WHERE id=?', single[1]);
    requireThat(a, 404, 'Appointment unavailable.');
    requireThat(actor.id === a.patient || actor.id === a.staff || isDesk(actor) ||
      (actor.role === 'staff' && !!store.get('SELECT 1 FROM care WHERE patient=? AND staff=?', a.patient, actor.id)),
    403, 'Appointment access denied.');
    return safeAppointment(a);
  }
  const appointmentAction = /^\/api\/appointments\/([^/]+)\/(cancel|check-in)$/.exec(path);
  if (appointmentAction && method === 'POST') {
    fields(body, ['expectedVersion', 'reason']);
    const [, appointmentId, action] = appointmentAction;
    return store.transaction(() => {
      const a = store.get('SELECT * FROM appointments WHERE id=?', appointmentId);
      requireThat(a, 404, 'Appointment unavailable.');
      if (action === 'check-in') {
        requireThat(isDesk(actor), 403, 'Front desk access required.');
        if (a.status === 'checkedIn') return safeAppointment(a); // repeated tap
      } else {
        requireThat(actor.id === a.patient || actor.id === a.staff || isDesk(actor), 403, 'You cannot change this appointment.');
        text(body.reason, 500);
      }
      requireThat(Number.isInteger(body.expectedVersion) && a.version === body.expectedVersion, 409, 'Changed by another user. Reload before saving.');
      requireThat(a.status === 'booked', 409, 'This appointment can no longer be changed.');
      if (action === 'check-in') {
        store.run("UPDATE appointments SET status='checkedIn',checked_in=?,version=version+1 WHERE id=?", now(), a.id);
      } else {
        store.run("UPDATE appointments SET status='cancelled',version=version+1 WHERE id=?", a.id);
      }
      store.audit(actor.id, `appointment.${action}`, a.id);
      return safeAppointment(store.get('SELECT * FROM appointments WHERE id=?', a.id));
    });
  }

  // ---- messaging ----------------------------------------------------------
  function threadAccess(patientId, staffId) {
    requireThat(actor.id === patientId || actor.id === staffId, 403, 'Conversation access denied.');
    requireThat(store.get('SELECT 1 FROM care WHERE patient=? AND staff=?', patientId, staffId), 403,
      'Messages need an existing care relationship.');
  }
  if (path === '/api/threads' && method === 'GET') {
    const mine = actor.role === 'patient' ? 'patient' : 'staff';
    requireThat(actor.role !== 'admin', 403, 'Clinical messages are not available to administrators.');
    const other = mine === 'patient' ? 'staff' : 'patient';
    return store.all(`SELECT m.${other} AS counterpartId, u.name AS counterpartName, max(m.at) AS lastAt,
        sum(CASE WHEN m.sender!=? AND m.read_at IS NULL THEN 1 ELSE 0 END) AS unread,
        (SELECT body FROM messages l WHERE l.patient=m.patient AND l.staff=m.staff ORDER BY at DESC, rowid DESC LIMIT 1) AS lastBody,
        (SELECT sender FROM messages l WHERE l.patient=m.patient AND l.staff=m.staff ORDER BY at DESC, rowid DESC LIMIT 1) AS lastSender,
        (SELECT id FROM messages l WHERE l.patient=m.patient AND l.staff=m.staff ORDER BY at DESC, rowid DESC LIMIT 1) AS lastId
      FROM messages m JOIN users u ON u.id=m.${other} WHERE m.${mine}=? GROUP BY m.${other} ORDER BY lastAt DESC`,
    actor.id, actor.id).map(r => ({ ...r, lastAt: new Date(r.lastAt).toISOString() }));
  }
  if (path === '/api/messages' && method === 'GET') {
    const patientId = text(url.searchParams.get('patientId'), 128), staffId = text(url.searchParams.get('staffId'), 128);
    threadAccess(patientId, staffId);
    return store.all('SELECT id,sender,body,at,read_at FROM messages WHERE patient=? AND staff=? ORDER BY at,id', patientId, staffId)
      .map(m => ({ id: m.id, senderId: m.sender, body: m.body, at: new Date(m.at).toISOString(),
        readAt: m.read_at ? new Date(m.read_at).toISOString() : null }));
  }
  if (path === '/api/messages' && method === 'POST') {
    fields(body, ['patientId', 'staffId', 'body', 'idempotencyKey']);
    const patientId = text(body.patientId, 128), staffId = text(body.staffId, 128);
    threadAccess(patientId, staffId);
    const message = text(body.body, 4000);
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const messageId = id();
      store.run('INSERT INTO messages(id,patient,staff,sender,body,at) VALUES(?,?,?,?,?,?)', messageId, patientId, staffId, actor.id, message, now());
      store.audit(actor.id, 'message.sent', messageId);
      return { id: messageId, senderId: actor.id, body: message, at: new Date(now()).toISOString(), readAt: null };
    }));
  }
  if (path === '/api/messages/read' && method === 'POST') {
    fields(body, ['patientId', 'staffId']);
    const patientId = text(body.patientId, 128), staffId = text(body.staffId, 128);
    threadAccess(patientId, staffId);
    store.run('UPDATE messages SET read_at=? WHERE patient=? AND staff=? AND sender!=? AND read_at IS NULL', now(), patientId, staffId, actor.id);
    return { ok: true };
  }

  // ---- desk billing -------------------------------------------------------
  if (path === '/api/invoices' && method === 'GET') {
    const patientId = url.searchParams.get('patientId') ?? (actor.role === 'patient' ? actor.id : null);
    requireThat(patientId, 400, 'Choose a patient.');
    if (actor.role === 'patient') requireThat(actor.id === patientId, 403, 'Patient access denied.');
    else requireThat(isDesk(actor), 403, 'Billing access required.');
    return store.all('SELECT * FROM invoices WHERE patient=? ORDER BY created DESC', patientId).map(safeInvoice);
  }
  if (path === '/api/invoices' && method === 'POST') {
    fields(body, ['patientId', 'description', 'amountFils', 'idempotencyKey']);
    requireThat(actor.role === 'admin', 403, 'Administrator access required.');
    const patientId = text(body.patientId, 128);
    requireThat(store.get("SELECT 1 FROM users WHERE id=? AND role='patient'", patientId), 404, 'Patient unavailable.');
    requireThat(Number.isInteger(body.amountFils) && body.amountFils > 0 && body.amountFils <= 100000000, 400, 'Enter an amount in fils.');
    const description = text(body.description, 200);
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const invoiceId = id();
      store.run('INSERT INTO invoices(id,patient,description,amount_fils,created) VALUES(?,?,?,?,?)', invoiceId, patientId, description, body.amountFils, now());
      store.audit(actor.id, 'invoice.issued', invoiceId);
      return safeInvoice(store.get('SELECT * FROM invoices WHERE id=?', invoiceId));
    }));
  }
  const pay = /^\/api\/invoices\/([^/]+)\/payments$/.exec(path);
  if (pay && method === 'POST') {
    fields(body, ['amountFils', 'expectedVersion', 'idempotencyKey']);
    requireThat(isDesk(actor), 403, 'Front desk or administrator access required.');
    requireThat(Number.isInteger(body.amountFils) && body.amountFils > 0, 400, 'Enter an amount in fils.');
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const invoice = store.get('SELECT * FROM invoices WHERE id=?', pay[1]);
      requireThat(invoice, 404, 'Invoice unavailable.');
      requireThat(Number.isInteger(body.expectedVersion) && invoice.version === body.expectedVersion, 409, 'Changed by another user. Reload before saving.');
      requireThat(invoice.status === 'outstanding', 409, 'This invoice is already paid.');
      const due = invoice.amount_fils - invoice.paid_fils;
      requireThat(body.amountFils <= due, 400, 'The amount is more than what is due.');
      store.run("INSERT INTO payments(id,invoice,amount_fils,method,recorded_by,at) VALUES(?,?,?,'desk',?,?)", id(), invoice.id, body.amountFils, actor.id, now());
      const paid = invoice.paid_fils + body.amountFils;
      store.run('UPDATE invoices SET paid_fils=?,status=?,version=version+1 WHERE id=?', paid, paid === invoice.amount_fils ? 'paid' : 'outstanding', invoice.id);
      store.audit(actor.id, 'payment.deskRecorded', invoice.id);
      return { ...safeInvoice(store.get('SELECT * FROM invoices WHERE id=?', invoice.id)), recordedOnly: true };
    }));
  }
  return undefined;
}

export { ApiError };
