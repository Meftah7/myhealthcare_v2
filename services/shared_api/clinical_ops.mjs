// Shared-mode clinic directory, slots, consultations (draft → sign),
// prescriptions, pharmacy (dispense + stock) and dental chart.
//
// Authorization mirrors the local app: role/job sets the permission set,
// care relationships scope patient data, signed records are immutable and
// writes are versioned or idempotent. Nothing is reported as done before it
// is stored.
import { availableDoctorSlots } from './workspace_ops.mjs';
import { fields, id, requireThat, text } from './store.mjs';

const clinical = ['doctor', 'nurse', 'dentist'];
const signers = ['doctor', 'dentist'];
const outcomes = ['dispensed', 'partial', 'held', 'clarificationRequested'];
const kinds = ['observation', 'planned', 'completed'];

function iso(ms) { return ms == null ? null : new Date(ms).toISOString(); }
function isFdi(n) {
  const q = Math.floor(n / 10), t = n % 10;
  return Number.isInteger(n) && ((q >= 1 && q <= 4 && t >= 1 && t <= 8) || (q >= 5 && q <= 8 && t >= 1 && t <= 5));
}
function meds(value) {
  requireThat(Array.isArray(value) && value.length <= 30, 400, 'Invalid medications.');
  return value.map(m => {
    requireThat(m && typeof m === 'object', 400, 'Invalid medication.');
    return { name: text(m.name, 200), dose: m.dose == null ? null : text(m.dose, 100),
      frequency: m.frequency == null ? null : text(m.frequency, 100) };
  });
}

/** Returns a result for a handled route, or `undefined` to fall through. */
export function clinicalOps({ store, now, path, method, url, body, actor }) {
  const job = actor.role === 'staff' ? actor.job : null;
  const hasCare = patient => clinical.includes(job) && (
    !!store.get('SELECT 1 FROM care WHERE patient=? AND staff=?', patient, actor.id) ||
    !!store.get('SELECT 1 FROM appointments WHERE patient=? AND staff=?',patient,actor.id) ||
    !!store.get('SELECT 1 FROM encounter_participants ep JOIN appointments a ON a.id=ep.appointment WHERE a.patient=? AND ep.staff=?',patient,actor.id));
  const safeStaff = u => ({ id: u.id, fullName: u.name, job: u.job, departmentId: u.department, specialty: u.specialty });

  // ---- directory ------------------------------------------------------------
  if (path === '/api/departments' && method === 'GET') {
    return store.all('SELECT id,name,description FROM departments ORDER BY name');
  }
  if (path === '/api/clinicians' && method === 'GET') {
    const dept = url.searchParams.get('departmentId');
    return store.all(`SELECT * FROM users WHERE role='staff' AND active=1 AND job IN ('doctor','dentist')
      ${dept ? 'AND department=?' : ''} ORDER BY name`, ...(dept ? [dept] : [])).map(safeStaff);
  }
  if (path === '/api/staff' && method === 'GET') {
    requireThat(actor.role !== 'patient', 403, 'Staff directory is for staff.');
    return store.all("SELECT * FROM users WHERE role='staff' AND active=1 ORDER BY name").map(safeStaff);
  }
  if (path === '/api/slots' && method === 'GET') {
    const staffId = text(url.searchParams.get('staffId'), 128), day = text(url.searchParams.get('day'), 10);
    requireThat(/^\d{4}-\d{2}-\d{2}$/.test(day), 400, 'Use YYYY-MM-DD.');
    return availableDoctorSlots(store,staffId,day,now());
  }
  if (path === '/api/patients' && method === 'GET') {
    const q = `%${(url.searchParams.get('query') ?? '').trim().toLowerCase()}%`;
    const desk = actor.role === 'admin' || job === 'receptionist';
    requireThat(desk || clinical.includes(job), 403, 'Patient search is for clinicians and the front desk.');
    const limit=Number(url.searchParams.get('limit')??50),offset=Number(url.searchParams.get('offset')??0);
    requireThat(Number.isInteger(limit)&&limit>0&&limit<=200&&Number.isInteger(offset)&&offset>=0,400,'Invalid page.');
    const rows = desk
      ? store.all("SELECT * FROM users WHERE role='patient' AND (lower(name) LIKE ? OR lower(email) LIKE ?) ORDER BY name,id LIMIT ? OFFSET ?", q, q,limit,offset)
      : store.all(`SELECT users.* FROM users WHERE users.role='patient' AND (
          EXISTS(SELECT 1 FROM care WHERE care.patient=users.id AND care.staff=?) OR
          EXISTS(SELECT 1 FROM appointments a WHERE a.patient=users.id AND a.staff=?) OR
          EXISTS(SELECT 1 FROM encounter_participants ep JOIN appointments a ON a.id=ep.appointment WHERE a.patient=users.id AND ep.staff=?))
          AND (lower(users.name) LIKE ? OR lower(users.email) LIKE ?) ORDER BY users.name,users.id LIMIT ? OFFSET ?`, actor.id,actor.id,actor.id,q,q,limit,offset);
    return rows.map(u => store.safeUser(u));
  }

  const onePatient = /^\/api\/patients\/([^/]+)$/.exec(path);
  if (onePatient && method === 'GET') {
    const desk = actor.role === 'admin' || job === 'receptionist';
    const p = store.get("SELECT * FROM users WHERE id=? AND role='patient'", onePatient[1]);
    requireThat(p, 404, 'Patient unavailable.');
    requireThat(actor.id === p.id || desk || (clinical.includes(job) && hasCare(p.id)) || job === 'pharmacist',
      403, 'Patient access denied.');
    return store.safeUser(p);
  }

  // ---- consultations ------------------------------------------------------
  const enc = /^\/api\/encounters\/([^/]+)(?:\/(draft|finalize|start))?$/.exec(path);
  if (enc) {
    const [, appointmentId, action] = enc;
    const appt = () => {
      const a = store.get('SELECT * FROM appointments WHERE id=?', appointmentId);
      requireThat(a, 404, 'Appointment unavailable.');
      requireThat(clinical.includes(job) && (a.staff === actor.id || hasCare(a.patient)), 403, 'Consultation access denied.');
      return a;
    };
    if (!action && method === 'GET') {
      const a = appt();
      const draft = store.get('SELECT * FROM encounter_drafts WHERE appointment=?', a.id);
      const signed = store.get('SELECT * FROM signed_notes WHERE appointment=?', a.id);
      return { appointmentId: a.id, status: a.status,
        draft: draft && { note: draft.note, meds: JSON.parse(draft.meds), version: draft.version, updatedAt: iso(draft.updated), authorId: draft.author },
        signed: signed && { note: signed.note, outcome: signed.outcome, signerId: signed.signer, signedAt: iso(signed.signed_at) } };
    }
    if (action === 'start' && method === 'POST') {
      fields(body, ['expectedVersion']);
      return store.transaction(() => {
        const a = appt();
        requireThat(a.staff === actor.id && signers.includes(job), 403, 'Only the booked clinician can start this visit.');
        if (a.status === 'inProgress') return { id: a.id, status: a.status, version: a.version };
        requireThat(a.version === body.expectedVersion, 409, 'Changed by another user. Reload before saving.');
        requireThat(['booked', 'checkedIn'].includes(a.status), 409, 'This visit cannot be started.');
        store.run("UPDATE appointments SET status='inProgress',version=version+1 WHERE id=?", a.id);
        store.audit(actor.id, 'encounter.started', a.id);
        const u = store.get('SELECT * FROM appointments WHERE id=?', a.id);
        return { id: u.id, status: u.status, version: u.version };
      });
    }
    if (action === 'draft' && method === 'POST') {
      fields(body, ['note', 'meds', 'expectedVersion']);
      requireThat(typeof body.note === 'string' && body.note.length <= 20000, 400, 'Invalid note.');
      const note = body.note;
      const list = meds(body.meds);
      return store.transaction(() => {
        const a = appt();
        requireThat(a.status === 'inProgress', 409, 'Start the visit before writing the note.');
        requireThat(!store.get('SELECT 1 FROM signed_notes WHERE appointment=?', a.id), 409, 'This note is already signed.');
        const prior = store.get('SELECT * FROM encounter_drafts WHERE appointment=?', a.id);
        if (prior) {
          requireThat(prior.version === body.expectedVersion, 409, 'The draft changed elsewhere. Reload it.');
          store.run('UPDATE encounter_drafts SET note=?,meds=?,author=?,updated=?,version=version+1 WHERE appointment=?',
            note, JSON.stringify(list), actor.id, now(), a.id);
        } else {
          store.run('INSERT INTO encounter_drafts(appointment,patient,author,note,meds,updated) VALUES(?,?,?,?,?,?)',
            a.id, a.patient, actor.id, note, JSON.stringify(list), now());
        }
        const d = store.get('SELECT * FROM encounter_drafts WHERE appointment=?', a.id);
        return { note: d.note, meds: JSON.parse(d.meds), version: d.version, updatedAt: iso(d.updated), authorId: d.author };
      });
    }
    if (action === 'finalize' && method === 'POST') {
      fields(body, ['note', 'meds', 'outcome', 'idempotencyKey']);
      const list = meds(body.meds);
      requireThat(typeof body.note === 'string' && body.note.length <= 20000, 400, 'Invalid note.');
      return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
        const a = appt();
        requireThat(a.staff === actor.id && signers.includes(job), 403, 'Only the booked doctor or dentist can sign.');
        requireThat(a.status === 'inProgress', 409, 'Start the visit before signing.');
        requireThat(body.note.trim() || list.length, 400, 'Add a note or medication before signing.');
        requireThat(!store.get('SELECT 1 FROM signed_notes WHERE appointment=?', a.id), 409, 'This note is already signed.');
        store.run('INSERT INTO signed_notes(appointment,patient,signer,note,outcome,signed_at) VALUES(?,?,?,?,?,?)',
          a.id, a.patient, actor.id, body.note, body.outcome == null ? null : text(body.outcome, 2000), now());
        for (const m of list) {
          store.run('INSERT INTO prescriptions(id,patient,prescriber,appointment,name,dose,frequency,start,issued_at) VALUES(?,?,?,?,?,?,?,?,?)',
            id(), a.patient, actor.id, a.id, m.name, m.dose, m.frequency, now(), now());
        }
        store.run('DELETE FROM encounter_drafts WHERE appointment=?', a.id);
        store.run("UPDATE appointments SET status='completed',completed_at=?,version=version+1 WHERE id=?", now(), a.id);
        store.audit(actor.id, 'encounter.signed', a.id);
        return { appointmentId: a.id, signerId: actor.id, signedAt: iso(now()), prescriptions: list.length };
      }));
    }
  }

  // ---- prescriptions and pharmacy -------------------------------------------
  if (path === '/api/prescriptions' && method === 'GET') {
    const patientId = text(url.searchParams.get('patientId'), 128);
    requireThat(actor.id === patientId || (clinical.includes(job) && hasCare(patientId)) || job === 'pharmacist',
      403, 'Prescription access denied.');
    return store.all(`SELECT p.*, u.name prescriberName FROM prescriptions p JOIN users u ON u.id=p.prescriber
      WHERE p.patient=? ORDER BY p.start DESC`, patientId).map(p => ({ id: p.id, patientId: p.patient,
      prescriberId: p.prescriber, prescriberName: p.prescriberName, appointmentId: p.appointment, name: p.name,
      dose: p.dose, frequency: p.frequency, startDate: iso(p.start), isActive: !!p.active }));
  }
  if (path === '/api/pharmacy/queue' && method === 'GET') {
    requireThat(job === 'pharmacist', 403, 'Pharmacy access required.');
    return store.all(`SELECT p.*, pt.name patientName, pr.name prescriberName,
        (SELECT outcome FROM dispenses d WHERE d.prescription=p.id ORDER BY at DESC, rowid DESC LIMIT 1) lastOutcome,
        (SELECT at FROM dispenses d WHERE d.prescription=p.id ORDER BY at DESC, rowid DESC LIMIT 1) lastAt
      FROM prescriptions p JOIN users pt ON pt.id=p.patient JOIN users pr ON pr.id=p.prescriber
      WHERE p.active=1 ORDER BY p.start DESC LIMIT 100`).map(p => ({ medicationId: p.id, patientId: p.patient,
      patientName: p.patientName, prescriberName: p.prescriberName, name: p.name, dose: p.dose, frequency: p.frequency,
      startDate: iso(p.start), lastOutcome: p.lastOutcome, lastOutcomeAt: iso(p.lastAt) }));
  }
  if (path === '/api/pharmacy/dispense' && method === 'POST') {
    fields(body, ['prescriptionId', 'outcome', 'patientVerified', 'quantity', 'batch', 'expiry', 'note', 'stockId', 'units', 'idempotencyKey']);
    requireThat(job === 'pharmacist', 403, 'Pharmacy access required.');
    requireThat(body.patientVerified === true, 400, "Verify the patient's identity against the order first.");
    requireThat(outcomes.includes(body.outcome), 400, 'Invalid outcome.');
    const supplying = ['dispensed', 'partial'].includes(body.outcome);
    if (supplying) requireThat(typeof body.quantity === 'string' && body.quantity.trim(), 400, 'Enter the quantity supplied.');
    if (body.outcome !== 'dispensed') requireThat(typeof body.note === 'string' && body.note.trim(), 400, 'Record the reason.');
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const p = store.get('SELECT * FROM prescriptions WHERE id=?', text(body.prescriptionId, 128));
      requireThat(p && p.active, 409, 'This order is no longer active.');
      requireThat(!store.get("SELECT 1 FROM dispenses WHERE prescription=? AND outcome='dispensed'", p.id), 409, 'This order has already been fully dispensed.');
      let batch = body.batch ?? null, expiry = body.expiry ? Date.parse(body.expiry) : null, stockId = null, units = null;
      if (body.stockId) {
        units = body.units;
        requireThat(Number.isInteger(units) && units > 0, 400, 'Enter how many units leave the batch.');
        const st = store.get('SELECT * FROM stock WHERE id=?', text(body.stockId, 128));
        requireThat(st, 409, 'That stock batch no longer exists.');
        requireThat(st.expiry > now(), 400, 'This batch has expired.');
        requireThat(st.quantity >= units, 409, `Only ${st.quantity} ${st.unit} left in batch ${st.batch}.`);
        store.run('UPDATE stock SET quantity=quantity-?,version=version+1 WHERE id=? AND version=?', units, st.id, st.version);
        batch = st.batch; expiry = st.expiry; stockId = st.id;
      } else if (supplying && expiry != null) {
        requireThat(Number.isFinite(expiry) && expiry > now(), 400, 'This batch has expired.');
      }
      store.run('INSERT INTO dispenses(id,prescription,patient,pharmacist,outcome,quantity,batch,expiry,note,stock,units,at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',
        id(), p.id, p.patient, actor.id, body.outcome, body.quantity ?? null, batch, expiry, body.note ?? null, stockId, units, now());
      store.audit(actor.id, `pharmacy.${body.outcome}`, p.id);
      return { recordedAt: iso(now()) };
    }));
  }
  if (path === '/api/pharmacy/stock' && method === 'GET') {
    requireThat(job === 'pharmacist', 403, 'Pharmacy access required.');
    return store.all('SELECT * FROM stock ORDER BY expiry').map(s => ({ id: s.id, itemName: s.item, batch: s.batch,
      expiry: iso(s.expiry), quantity: s.quantity, unit: s.unit, receivedAt: iso(s.received_at), version: s.version }));
  }
  if (path === '/api/pharmacy/stock' && method === 'POST') {
    fields(body, ['itemName', 'batch', 'expiry', 'quantity', 'unit', 'idempotencyKey']);
    requireThat(job === 'pharmacist', 403, 'Pharmacy access required.');
    const item = text(body.itemName, 200), batch = text(body.batch, 80), expiry = Date.parse(body.expiry);
    requireThat(Number.isInteger(body.quantity) && body.quantity > 0 && body.quantity <= 100000, 400, 'Enter a quantity from 1 to 100000.');
    requireThat(Number.isFinite(expiry) && expiry > now(), 400, 'This batch has already expired.');
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const stockId = id();
      store.run('INSERT INTO stock(id,item,batch,expiry,quantity,unit,received_by,received_at) VALUES(?,?,?,?,?,?,?,?)',
        stockId, item, batch, expiry, body.quantity, body.unit ? text(body.unit, 40) : 'units', actor.id, now());
      store.audit(actor.id, 'pharmacy.stock_received', stockId);
      const s = store.get('SELECT * FROM stock WHERE id=?', stockId);
      return { id: s.id, itemName: s.item, batch: s.batch, expiry: iso(s.expiry), quantity: s.quantity, unit: s.unit, receivedAt: iso(s.received_at), version: s.version };
    }));
  }

  // ---- dental chart -------------------------------------------------------------
  if (path === '/api/dental' && method === 'GET') {
    const patientId = text(url.searchParams.get('patientId'), 128);
    requireThat(clinical.includes(job) && hasCare(patientId), 403, 'Dental chart access denied.');
    return store.all('SELECT * FROM dental WHERE patient=? ORDER BY at, rowid', patientId).map(e => ({ id: e.id,
      patientId: e.patient, appointmentId: e.appointment, tooth: e.tooth, kind: e.kind, surface: e.surface,
      note: e.note, fulfilsId: e.fulfils, authorId: e.author, createdAt: iso(e.at) }));
  }
  if (path === '/api/dental' && method === 'POST') {
    fields(body, ['patientId', 'appointmentId', 'tooth', 'kind', 'surface', 'note', 'fulfilsId', 'idempotencyKey']);
    const patientId = text(body.patientId, 128);
    requireThat(job === 'dentist' && hasCare(patientId), 403, 'Only a dentist with a care relationship can chart.');
    requireThat(isFdi(body.tooth), 400, 'Choose a valid FDI tooth number.');
    requireThat(kinds.includes(body.kind), 400, 'Invalid entry kind.');
    const note = text(body.note, 1000);
    return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
      const a = store.get('SELECT * FROM appointments WHERE id=?', text(body.appointmentId, 128));
      requireThat(a && a.patient === patientId && a.status !== 'cancelled', 400, "Choose one of this patient's visits.");
      if (body.fulfilsId) {
        const plan = store.get('SELECT * FROM dental WHERE id=?', body.fulfilsId);
        requireThat(plan && plan.patient === patientId && plan.tooth === body.tooth && plan.kind === 'planned' && body.kind === 'completed',
          400, 'A completed entry can only fulfil a planned treatment on the same tooth.');
      }
      const entryId = id();
      store.run('INSERT INTO dental(id,patient,appointment,tooth,kind,surface,note,fulfils,author,at) VALUES(?,?,?,?,?,?,?,?,?,?)',
        entryId, patientId, a.id, body.tooth, body.kind, body.surface ? text(body.surface, 20) : null, note,
        body.fulfilsId ?? null, actor.id, now());
      store.audit(actor.id, `dental.${body.kind}`, entryId);
      const e = store.get('SELECT * FROM dental WHERE id=?', entryId);
      return { id: e.id, patientId: e.patient, appointmentId: e.appointment, tooth: e.tooth, kind: e.kind,
        surface: e.surface, note: e.note, fulfilsId: e.fulfils, authorId: e.author, createdAt: iso(e.at) };
    }));
  }
  return undefined;
}
