import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { Store, id } from './store.mjs';
import { createApi } from './server.mjs';

async function fixture(t) {
  const directory = mkdtempSync(join(tmpdir(), 'myhealth-ops-test-'));
  const clock = Date.now();
  const store = new Store({ directory: join(directory, 'data'), fileKey: randomBytes(32).toString('hex'), now: () => clock });
  const password = 'Synthetic-Test-Password-2026!';
  const users = {
    patient: store.addUser({ email: 'patient@test.demo', name: 'Test Patient', role: 'patient', password }),
    other: store.addUser({ email: 'other@test.demo', name: 'Other Patient', role: 'patient', password }),
    doctor: store.addUser({ email: 'doctor@test.demo', name: 'Test Doctor', role: 'staff', job: 'doctor', password }),
    nurse: store.addUser({ email: 'nurse@test.demo', name: 'Test Nurse', role: 'staff', job: 'nurse', password }),
    reception: store.addUser({ email: 'reception@test.demo', name: 'Desk', role: 'staff', job: 'receptionist', password }),
    admin: store.addUser({ email: 'admin@test.demo', name: 'Admin', role: 'admin', password }),
  };
  const server = createApi({ store, origins: [] });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  async function request(path, { method = 'GET', body, token } = {}) {
    const response = await fetch(base + path, { method, headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}) }, body: body ? JSON.stringify(body) : undefined });
    return { status: response.status, body: await response.json() };
  }
  const as = {};
  for (const role of Object.keys(users)) {
    const login = await request('/api/login', { method: 'POST', body: { email: `${role}@test.demo`, password } });
    assert.equal(login.status, 200);
    as[role] = (path, args = {}) => request(path, { ...args, token: login.body.token });
  }
  t.after(async () => { await new Promise(r => { server.close(r); server.closeAllConnections(); }); store.close(); rmSync(directory, { recursive: true, force: true }); });
  return { store, users, as, at: hours => new Date(clock + hours * 3600000).toISOString() };
}

test('booking: patient for self, desk for anyone; conflicts and retries are safe', async t => {
  const f = await fixture(t);
  const slot = { staffId: f.users.doctor, start: f.at(24), end: f.at(24.5), reason: null };
  const key = id();
  const first = await f.as.patient('/api/appointments', { method: 'POST', body: { ...slot, patientId: f.users.patient, idempotencyKey: key } });
  assert.equal(first.status, 200);
  const retry = await f.as.patient('/api/appointments', { method: 'POST', body: { ...slot, patientId: f.users.patient, idempotencyKey: key } });
  assert.equal(retry.body.id, first.body.id);
  // Same slot for someone else: conflict, nothing written.
  const clash = await f.as.reception('/api/appointments', { method: 'POST', body: { ...slot, patientId: f.users.other, idempotencyKey: id() } });
  assert.equal(clash.status, 409);
  assert.equal(f.store.get('SELECT count(*) n FROM appointments').n, 1);
  // A patient cannot book for another patient; a nurse cannot be booked.
  assert.equal((await f.as.patient('/api/appointments', { method: 'POST', body: { ...slot, start: f.at(30), end: f.at(30.5), patientId: f.users.other, idempotencyKey: id() } })).status, 403);
  assert.equal((await f.as.reception('/api/appointments', { method: 'POST', body: { ...slot, staffId: f.users.nurse, patientId: f.users.other, idempotencyKey: id() } })).status, 400);
  // Desk books for the other patient at a free time and checks them in once.
  const desk = await f.as.reception('/api/appointments', { method: 'POST', body: { ...slot, start: f.at(26), end: f.at(26.5), patientId: f.users.other, idempotencyKey: id() } });
  assert.equal(desk.status, 200);
  const checkIn = await f.as.reception(`/api/appointments/${desk.body.id}/check-in`, { method: 'POST', body: { expectedVersion: 1, reason: null } });
  assert.equal(checkIn.body.status, 'checkedIn');
  const again = await f.as.reception(`/api/appointments/${desk.body.id}/check-in`, { method: 'POST', body: { expectedVersion: 1, reason: null } });
  assert.equal(again.body.version, checkIn.body.version);
  // The patient cancels with a stale version (409), then the current one.
  assert.equal((await f.as.patient(`/api/appointments/${first.body.id}/cancel`, { method: 'POST', body: { expectedVersion: 9, reason: 'x' } })).status, 409);
  assert.equal((await f.as.patient(`/api/appointments/${first.body.id}/cancel`, { method: 'POST', body: { expectedVersion: 1, reason: 'Travelling' } })).body.status, 'cancelled');
  // The doctor sees only their own appointments; the other patient only theirs.
  assert.equal((await f.as.doctor('/api/appointments')).body.length, 2);
  assert.equal((await f.as.other('/api/appointments')).body.length, 1);
});

test('messages need a care relationship; retries never duplicate; admins cannot read', async t => {
  const f = await fixture(t);
  const body = { patientId: f.users.patient, staffId: f.users.doctor, body: 'Question about my results', idempotencyKey: id() };
  assert.equal((await f.as.patient('/api/messages', { method: 'POST', body })).status, 403);
  f.store.run('INSERT INTO care VALUES(?,?)', f.users.patient, f.users.doctor);
  assert.equal((await f.as.patient('/api/messages', { method: 'POST', body })).status, 200);
  assert.equal((await f.as.patient('/api/messages', { method: 'POST', body })).status, 200);
  assert.equal(f.store.get('SELECT count(*) n FROM messages').n, 1);
  const threads = await f.as.doctor('/api/threads');
  assert.equal(threads.body[0].unread, 1);
  await f.as.doctor('/api/messages/read', { method: 'POST', body: { patientId: f.users.patient, staffId: f.users.doctor } });
  assert.equal((await f.as.doctor('/api/threads')).body[0].unread, 0);
  assert.equal((await f.as.other(`/api/messages?patientId=${f.users.patient}&staffId=${f.users.doctor}`)).status, 403);
  assert.equal((await f.as.admin('/api/threads')).status, 403);
});

test('desk payments are integer fils, never exceed what is due, and are append-only', async t => {
  const f = await fixture(t);
  const invoice = await f.as.admin('/api/invoices', { method: 'POST', body: { patientId: f.users.patient, description: 'Consultation', amountFils: 15500, idempotencyKey: id() } });
  assert.equal(invoice.status, 200);
  assert.equal((await f.as.patient('/api/invoices')).body[0].amountFils, 15500);
  assert.equal((await f.as.doctor(`/api/invoices?patientId=${f.users.patient}`)).status, 403);
  const key = id();
  const part = await f.as.reception(`/api/invoices/${invoice.body.id}/payments`, { method: 'POST', body: { amountFils: 5500, expectedVersion: 1, idempotencyKey: key } });
  assert.equal(part.body.paidFils, 5500); assert.equal(part.body.recordedOnly, true);
  const retried = await f.as.reception(`/api/invoices/${invoice.body.id}/payments`, { method: 'POST', body: { amountFils: 5500, expectedVersion: 1, idempotencyKey: key } });
  assert.equal(retried.body.paidFils, 5500);
  assert.equal(f.store.get('SELECT count(*) n FROM payments').n, 1);
  assert.equal((await f.as.reception(`/api/invoices/${invoice.body.id}/payments`, { method: 'POST', body: { amountFils: 20000, expectedVersion: 2, idempotencyKey: id() } })).status, 400);
  const rest = await f.as.reception(`/api/invoices/${invoice.body.id}/payments`, { method: 'POST', body: { amountFils: 10000, expectedVersion: 2, idempotencyKey: id() } });
  assert.equal(rest.body.status, 'paid');
  assert.throws(() => f.store.run('DELETE FROM payments'));
  assert.equal((await f.as.admin('/api/health')).body.payments, 'deskRecordOnly');
});
