import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { Store, id } from './store.mjs';
import { createApi } from './server.mjs';

async function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), 'myhealth-clinical-test-'));
  const clock = Date.now();
  const store = new Store({ directory: join(directory, 'data'), fileKey: randomBytes(32).toString('hex'), now: () => clock });
  const password = 'Synthetic-Test-Password-2026!';
  const add = (role, job = null) => store.addUser({ email: `${job ?? role}@test.demo`, name: `Test ${job ?? role}`, role, job, password });
  const users = { patient: add('patient'), doctor: add('staff', 'doctor'), nurse: add('staff', 'nurse'),
    dentist: add('staff', 'dentist'), pharmacist: add('staff', 'pharmacist'), receptionist: add('staff', 'receptionist'),
    admin: add('admin') };
  const dept = id();
  store.run('INSERT INTO departments VALUES(?,?,?)', dept, 'Family Medicine', null);
  store.run('UPDATE users SET department=? WHERE id=?', dept, users.doctor);
  for (let weekday = 1; weekday <= 7; weekday++) {
    store.run('INSERT INTO schedules(staff,weekday,start_min,end_min) VALUES(?,?,?,?)', users.doctor, weekday, 0, 1440);
  }
  const server = createApi({ store, origins: [] });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  async function request(path, { method = 'GET', body, token } = {}) {
    const response = await fetch(base + path, { method, headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined });
    return { status: response.status, body: await response.json() };
  }
  const as = {};
  for (const [name] of Object.entries(users)) {
    const email = `${name === 'patient' || name === 'admin' ? name : name}@test.demo`;
    const login = await request('/api/login', { method: 'POST', body: { email, password } });
    assert.equal(login.status, 200, name);
    as[name] = (path, args = {}) => request(path, { ...args, token: login.body.token });
  }
  t.after(async () => { await new Promise(r => { server.close(r); server.closeAllConnections(); }); store.close(); rmSync(directory, { recursive: true, force: true }); });
  return { store, users, as, dept, clock };
}

async function bookedVisit(f) {
  const day = new Date(f.clock + 2 * 86400000).toISOString().slice(0, 10);
  const slots = await f.as.patient(`/api/slots?staffId=${f.users.doctor}&day=${day}`);
  assert.ok(slots.body.length > 0);
  const slot = slots.body[0];
  const booked = await f.as.patient('/api/appointments', { method: 'POST', body: {
    patientId: f.users.patient, staffId: f.users.doctor, start: slot.start, end: slot.end, reason: null, idempotencyKey: id() } });
  assert.equal(booked.status, 200);
  // The booked slot disappears from the open slots.
  const after = await f.as.patient(`/api/slots?staffId=${f.users.doctor}&day=${day}`);
  assert.ok(!after.body.some(s => s.start === slot.start));
  return booked.body;
}

test('directory and slots come from the server', async t => {
  const f = await fixture(t);
  assert.equal((await f.as.patient('/api/departments')).body[0].name, 'Family Medicine');
  const clinicians = await f.as.patient(`/api/clinicians?departmentId=${f.dept}`);
  assert.deepEqual(clinicians.body.map(c => c.id), [f.users.doctor]);
  await bookedVisit(f);
  // Desk searches all patients; a clinician only those in their care.
  assert.equal((await f.as.receptionist('/api/patients?query=test')).body.length, 1);
  assert.equal((await f.as.nurse('/api/patients?query=test')).body.length, 0);
  assert.equal((await f.as.patient('/api/patients?query=test')).status, 403);
});

test('consultation: draft is versioned, only the booked doctor signs, signing is once', async t => {
  const f = await fixture(t);
  const visit = await bookedVisit(f);
  const enc = `/api/encounters/${visit.id}`;
  assert.equal((await f.as.dentist(enc)).status, 403);
  assert.equal((await f.as.doctor(`${enc}/start`, { method: 'POST', body: { expectedVersion: visit.version } })).body.status, 'inProgress');
  const draft = await f.as.doctor(`${enc}/draft`, { method: 'POST', body: { note: 'Cough 3 days', meds: [{ name: 'Paracetamol', dose: '500 mg', frequency: 'tds' }], expectedVersion: null } });
  assert.equal(draft.body.version, 1);
  assert.equal((await f.as.doctor(`${enc}/draft`, { method: 'POST', body: { note: 'x', meds: [], expectedVersion: 9 } })).status, 409);
  // A nurse with a care link may draft but cannot sign.
  f.store.run('INSERT INTO care VALUES(?,?)', f.users.patient, f.users.nurse);
  assert.equal((await f.as.nurse(`${enc}/draft`, { method: 'POST', body: { note: 'Obs normal', meds: [], expectedVersion: 1 } })).body.version, 2);
  const finalize = { note: 'Viral URTI', meds: [{ name: 'Paracetamol', dose: '500 mg', frequency: 'tds' }], outcome: null, idempotencyKey: id() };
  assert.equal((await f.as.nurse(`${enc}/finalize`, { method: 'POST', body: finalize })).status, 403);
  assert.equal((await f.as.doctor(`${enc}/finalize`, { method: 'POST', body: finalize })).status, 200);
  assert.equal((await f.as.doctor(`${enc}/finalize`, { method: 'POST', body: finalize })).status, 200); // retry
  assert.equal(f.store.get('SELECT count(*) n FROM prescriptions').n, 1);
  assert.equal((await f.as.doctor(enc)).body.status, 'completed');
  assert.throws(() => f.store.run("UPDATE signed_notes SET note='edited'"));
  // The patient sees their prescription.
  assert.equal((await f.as.patient(`/api/prescriptions?patientId=${f.users.patient}`)).body[0].name, 'Paracetamol');
});

test('pharmacy dispenses from stock exactly once', async t => {
  const f = await fixture(t);
  const visit = await bookedVisit(f);
  await f.as.doctor(`/api/encounters/${visit.id}/start`, { method: 'POST', body: { expectedVersion: visit.version } });
  await f.as.doctor(`/api/encounters/${visit.id}/finalize`, { method: 'POST', body: { note: 'n', meds: [{ name: 'Amoxicillin' }], outcome: null, idempotencyKey: id() } });
  const order = (await f.as.pharmacist('/api/pharmacy/queue')).body[0];
  assert.equal(order.name, 'Amoxicillin');
  assert.equal((await f.as.receptionist('/api/pharmacy/queue')).status, 403);
  const stock = await f.as.pharmacist('/api/pharmacy/stock', { method: 'POST', body: {
    itemName: 'Amoxicillin', batch: 'L1', expiry: new Date(f.clock + 90 * 86400000).toISOString(), quantity: 10, unit: 'caps', idempotencyKey: id() } });
  const take = key => ({ prescriptionId: order.medicationId, outcome: 'partial', patientVerified: true, quantity: '4',
    batch: null, expiry: null, note: 'Rest later', stockId: stock.body.id, units: 4, idempotencyKey: key });
  const key = id();
  assert.equal((await f.as.pharmacist('/api/pharmacy/dispense',{method:'POST',body:{...take('untracked-stock'),stockId:null,units:null}})).status,400);
  assert.equal(f.store.get('SELECT COUNT(*) n FROM dispenses').n,0);
  assert.equal((await f.as.pharmacist('/api/pharmacy/dispense', { method: 'POST', body: take(key) })).status, 200);
  assert.equal((await f.as.pharmacist('/api/pharmacy/dispense', { method: 'POST', body: take(key) })).status, 200);
  assert.equal((await f.as.pharmacist('/api/pharmacy/stock')).body[0].quantity, 6);
  assert.equal((await f.as.pharmacist('/api/pharmacy/dispense', { method: 'POST', body: { ...take(id()), units: 7 } })).status, 409);
  assert.throws(() => f.store.run('DELETE FROM dispenses'));
});

test('dental chart: dentist with care writes; others cannot', async t => {
  const f = await fixture(t);
  const visit = await bookedVisit(f);
  const entry = { patientId: f.users.patient, appointmentId: visit.id, tooth: 36, kind: 'planned', surface: 'O', note: 'Caries', fulfilsId: null, idempotencyKey: id() };
  assert.equal((await f.as.dentist('/api/dental', { method: 'POST', body: entry })).status, 403);
  f.store.run('INSERT INTO care VALUES(?,?)', f.users.patient, f.users.dentist);
  const plan = await f.as.dentist('/api/dental', { method: 'POST', body: entry });
  assert.equal(plan.status, 200);
  assert.equal((await f.as.dentist('/api/dental', { method: 'POST', body: { ...entry, tooth: 19, idempotencyKey: id() } })).status, 400);
  assert.equal((await f.as.doctor('/api/dental', { method: 'POST', body: { ...entry, idempotencyKey: id() } })).status, 403);
  assert.equal((await f.as.dentist(`/api/dental?patientId=${f.users.patient}`)).body.length, 1);
  assert.equal((await f.as.receptionist(`/api/dental?patientId=${f.users.patient}`)).status, 403);
});
