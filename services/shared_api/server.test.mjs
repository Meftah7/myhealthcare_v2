import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { Store, id, digest } from './store.mjs';
import { createApi } from './server.mjs';
import { deliverPending, encryptedBackup, restoreBackup, renderEnglishPdf, renderPending } from './workers.mjs';

async function fixture(t, options = {}) {
  const directory = mkdtempSync(join(tmpdir(), 'myhealth-shared-test-')), key = randomBytes(32).toString('hex');
  let clock = Date.now();
  const store = new Store({ directory: join(directory, 'data'), fileKey: key, now: () => clock });
  const password = 'Synthetic-Test-Password-2026!';
  const patient = store.addUser({ email: 'patient@test.demo', name: 'Test Patient', role: 'patient', password });
  const other = store.addUser({ email: 'other@test.demo', name: 'Other Patient', role: 'patient', password });
  const doctor = store.addUser({ email: 'doctor@test.demo', name: 'Test Doctor', role: 'staff', job: 'doctor', password, credentialUntil: clock + 86400000 });
  const nurse = store.addUser({ email: 'nurse@test.demo', name: 'Test Nurse', role: 'staff', job: 'nurse', password });
  const unrelated = store.addUser({ email: 'unrelated@test.demo', name: 'Unrelated Doctor', role: 'staff', job: 'doctor', password, credentialUntil: clock + 86400000 });
  const admin = store.addUser({ email: 'admin@test.demo', name: 'Test Admin', role: 'admin', password });
  store.run('INSERT INTO care VALUES(?,?)', patient, doctor); store.run('INSERT INTO care VALUES(?,?)', patient, nurse);
  const visit = id(); store.run("INSERT INTO visits(id,patient,staff,at,status) VALUES(?,?,?,?,'completed')", visit, patient, doctor, clock);
  store.run("INSERT INTO settings VALUES('clinicName','Test Clinic')");
  const server = createApi({ store, origins: ['http://localhost:8080'], renderDocument: renderEnglishPdf, ...options });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  const clients = {};
  async function request(path, { method = 'GET', body, token, headers = {} } = {}) {
    const response = await fetch(base + path, { method, headers: { ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}), ...headers }, body: body ? JSON.stringify(body) : undefined });
    return { status: response.status, body: response.headers.get('content-type')?.includes('json') ? await response.json() : Buffer.from(await response.arrayBuffer()) };
  }
  for (const role of ['patient','other','doctor','nurse','unrelated','admin']) {
    const response = await request('/api/login', { method: 'POST', body: { email: `${role}@test.demo`, password } });
    assert.equal(response.status, 200); clients[role] = (path, args = {}) => request(path, { ...args, token: response.body.token });
    clients[role].token = response.body.token;
  }
  t.after(async () => { await new Promise(r => { server.close(r); server.closeAllConnections(); }); store.close(); rmSync(directory, { recursive: true, force: true }); });
  return { store, directory, key, request, clients, patient, other, doctor, nurse, unrelated, admin, visit,
    advance: ms => { clock += ms; } };
}
async function prepared(f, { approved = true, language = 'en' } = {}) {
  const template = await f.clients.admin('/api/templates', { method: 'POST', body: {
    type: 'sickLeaveCertificate', language, disclosure: 'employer', approved, reason: 'Synthetic test approval only',
    wording: '{patientName} attended on {visitDate}. Leave from {startDate} to {endDate}.' } });
  assert.equal(template.status, 200);
  const request = await f.clients.doctor('/api/requests', { method: 'POST', body: {
    patientId: f.patient, visitId: f.visit, templateId: template.body.id,
    content: { startDate: '2026-10-09', endDate: '2026-10-10' }, idempotencyKey: id() } });
  assert.equal(request.status, 200);
  const submitted = await f.clients.doctor(`/api/requests/${request.body.id}/submit`, { method: 'POST', body: { expectedVersion: 1 } });
  assert.equal(submitted.status, 200); return { request: submitted.body, template: template.body };
}
async function issued(f) {
  const p = await prepared(f);
  assert.equal((await f.clients.doctor(`/api/requests/${p.request.id}/approve`, { method: 'POST', body: { expectedVersion: 2 } })).status, 200);
  const body = { expectedVersion: 3, idempotencyKey: id() }, path = `/api/requests/${p.request.id}/issue`;
  const result = await f.clients.doctor(path, { method: 'POST', body }); assert.equal(result.status, 200);
  return { ...result.body, path, body };
}

test('independent clients share versioned tasks without cross-panel access or duplicate regeneration', async t => {
  const f = await fixture(t), input = { patientId: f.patient, sourceId: 'visit:followup', title: 'Review visit', kind: 'followUpDue', idempotencyKey: id() };
  const first = await f.clients.doctor('/api/tasks', { method: 'POST', body: input }); assert.equal(first.status, 200);
  assert.equal((await f.clients.unrelated(`/api/tasks/${first.body.id}`, { method: 'PATCH', body: { status: 'done', outcome: 'Forged', expectedVersion: 1 } })).status, 403);
  const secondLogin = await f.request('/api/login', { method: 'POST', body: { email: 'doctor@test.demo', password: 'Synthetic-Test-Password-2026!' } });
  assert.equal((await f.request('/api/tasks', { token: secondLogin.body.token })).body.length, 1);
  assert.equal((await f.clients.doctor(`/api/tasks/${first.body.id}`, { method: 'PATCH', body: { status: 'done', outcome: 'Follow-up recorded', expectedVersion: 1 } })).status, 200);
  assert.equal((await f.request('/api/tasks', { token: secondLogin.body.token })).body[0].status, 'done');
  assert.equal((await f.clients.doctor(`/api/tasks/${first.body.id}`, { method: 'PATCH', body: { status: 'waiting', outcome: 'Stale', expectedVersion: 1 } })).status, 409);
  const regenerated = await f.clients.doctor('/api/tasks', { method: 'POST', body: { ...input, idempotencyKey: id() } });
  assert.equal(regenerated.body.status, 'done'); assert.equal(f.store.get('SELECT count(*) n FROM task_history').n, 1);
  assert.throws(() => f.store.run('DELETE FROM task_history'));
  f.store.run('DELETE FROM care WHERE patient=? AND staff=?', f.patient, f.doctor);
  assert.deepEqual((await f.clients.doctor('/api/tasks')).body, []);
  assert.equal((await f.clients.doctor(`/api/tasks/${first.body.id}/history`)).status, 403);
});

test('official issuance needs clinic approval and a current doctor; source patients and disclosures are checked', async t => {
  const f = await fixture(t), p = await prepared(f, { approved: false });
  assert.equal((await f.clients.doctor(`/api/requests/${p.request.id}/approve`, { method: 'POST', body: { expectedVersion: 2 } })).status, 403);
  assert.equal((await f.clients.admin(`/api/requests/${p.request.id}/approve`, { method: 'POST', body: { expectedVersion: 2 } })).status, 403);
  assert.equal((await f.clients.nurse(`/api/requests/${p.request.id}/approve`, { method: 'POST', body: { expectedVersion: 2 } })).status, 403);
  const bad = await f.clients.doctor('/api/requests', { method: 'POST', body: { patientId: f.other, visitId: f.visit,
    templateId: p.template.id, content: { startDate: '2026-10-09', endDate: '2026-10-10', diagnosis: 'Disclosure leak' }, idempotencyKey: id() } });
  assert.equal(bad.status, 403);
  f.store.run('UPDATE templates SET approved=1 WHERE id=?', p.template.id);
  f.store.run('UPDATE users SET credential_until=0 WHERE id=?', f.doctor);
  assert.equal((await f.clients.doctor(`/api/requests/${p.request.id}/approve`, { method: 'POST', body: { expectedVersion: 2 } })).status, 403);
});

test('one frozen issue, exact encrypted PDF, minimal live verification and idempotent in-app delivery across devices', async t => {
  const f = await fixture(t), doc = await issued(f);
  const retry = await f.clients.doctor(doc.path, { method: 'POST', body: doc.body }); assert.equal(retry.body.id, doc.id);
  assert.equal(f.store.get('SELECT count(*) n FROM documents').n, 1);
  assert.equal((await f.clients.patient(`/api/documents?patientId=${f.patient}`)).body[0].id, doc.id);
  assert.equal((await f.clients.other(`/api/documents/${doc.id}/download`)).status, 403);
  assert.equal((await f.clients.admin(`/api/documents/${doc.id}/download`)).status, 403);
  f.store.run("UPDATE users SET name='Changed Profile' WHERE id=?", f.patient);
  assert.equal((await f.clients.doctor(`/api/documents/${doc.id}/render`, { method: 'POST', body: {} })).status, 200);
  const pdf = await f.clients.patient(`/api/documents/${doc.id}/download`); assert.equal(pdf.status, 200);
  assert.match(pdf.body.toString(), /Test Patient/); assert.doesNotMatch(pdf.body.toString(), /Changed Profile/);
  assert.ok(pdf.body.toString().includes(doc.reference));
  const record = f.store.get('SELECT * FROM documents WHERE id=?', doc.id);
  assert.doesNotMatch(readFileSync(f.store.filePath(record.file_id)).toString(), /Test Patient/);
  const verified = await f.request(`/api/verify/${doc.reference}?sha256=${digest(pdf.body)}`);
  assert.equal(verified.body.fileMatch, true); assert.deepEqual(Object.keys(verified.body).sort(), ['asOf','documentType','fileMatch','issuedAt','validity']);
  deliverPending(f.store, { fail: true }); assert.equal(f.store.get('SELECT state FROM deliveries').state, 'failed');
  f.advance(31000); deliverPending(f.store); deliverPending(f.store);
  assert.equal((await f.clients.patient('/api/notifications')).body.length, 1);
  assert.equal((await f.clients.doctor(`/api/documents/${doc.id}/revoke`, { method: 'POST', body: { expectedVersion: 1, reason: 'Issued in error' } })).status, 200);
  assert.equal((await f.request(`/api/verify/${doc.reference}`)).body.validity, 'revoked');
  assert.throws(() => f.store.run("UPDATE documents SET snapshot='{}' WHERE id=?", doc.id));
});

test('revocation during async rendering and session expiry are enforced on the server', async t => {
  let release, started;
  const ready = new Promise(r => { started = r; });
  const f = await fixture(t, { renderDocument: async snapshot => { started(); await new Promise(r => { release = r; }); return renderEnglishPdf(snapshot); } });
  const doc = await issued(f), pending = f.clients.doctor(`/api/documents/${doc.id}/render`, { method: 'POST', body: {} });
  await ready; f.store.run('UPDATE users SET active=0 WHERE id=?', f.doctor); release();
  assert.equal((await pending).status, 401); assert.equal(f.store.get('SELECT render FROM documents').render, 'pending');
  f.advance(10 * 60000); assert.equal((await f.clients.patient('/api/session')).status, 200);
  f.advance(10 * 60000); assert.equal((await f.clients.patient('/api/session')).status, 200);
  f.advance(5 * 60000); assert.equal((await f.clients.patient('/api/session')).status, 401);
  assert.equal((await f.request('/api/session')).status, 401);
});

test('encrypted backup restores exact files, schema and data while invalidating sessions; wrong keys and overwrite fail', async t => {
  const f = await fixture(t), backupKey = randomBytes(32).toString('hex');
  const original = Buffer.from('%PDF-1.4\nSynthetic original\n%%EOF');
  const uploaded = await f.clients.patient('/api/originals', { method: 'POST', body: { patientId: f.patient, base64: original.toString('base64'), idempotencyKey: id() } });
  assert.equal(uploaded.status, 200);
  const archive = await encryptedBackup(f.store, { directory: join(f.directory, 'backups'), key: backupKey });
  assert.doesNotMatch(readFileSync(archive).toString(), /Test Patient|Synthetic original|password_hash/);
  assert.throws(() => restoreBackup({ archive, key: randomBytes(32).toString('hex'), directory: join(f.directory, 'bad') }));
  const target = join(f.directory, 'restored'); restoreBackup({ archive, key: backupKey, directory: target });
  assert.throws(() => restoreBackup({ archive, key: backupKey, directory: target }));
  const restored = new Store({ directory: target, fileKey: f.key });
  try { assert.deepEqual(restored.readFile(uploaded.body.id), original); assert.equal(restored.get('SELECT count(*) n FROM sessions').n, 0);
    assert.equal(restored.get('PRAGMA user_version').user_version, 1); }
  finally { restored.close(); }
  assert.equal(existsSync(join(target, '.restore-incomplete')), false);
});

test('admin health, request allowlists, CORS, deactivation and safe retry conflicts', async t => {
  const f = await fixture(t);
  assert.equal((await f.clients.patient('/api/health')).status, 403);
  const health = await f.clients.admin('/api/health'); assert.equal(health.body.storage, 'ok'); assert.equal(health.body.payments, 'notConfigured');
  assert.equal((await f.clients.admin(`/api/people/${f.admin}/active`, { method: 'POST', body: { active: false, reason: 'Self' } })).status, 400);
  assert.equal((await f.clients.patient('/api/session', { headers: { Origin: 'https://evil.example' } })).status, 403);
  const key = id(), base = { patientId: f.patient, sourceId: 'test', title: 'Test', kind: 'followUpDue', idempotencyKey: key };
  assert.equal((await f.clients.doctor('/api/tasks', { method: 'POST', body: { ...base, owner: f.unrelated } })).status, 400);
  assert.equal((await f.clients.doctor('/api/tasks', { method: 'POST', body: base })).status, 200);
  assert.equal((await f.clients.doctor('/api/tasks', { method: 'POST', body: { ...base, title: 'Changed' } })).status, 409);
  assert.equal((await f.clients.admin(`/api/people/${f.doctor}/active`, { method: 'POST', body: { active: false, reason: 'Transfer first' } })).status, 409);
});

test('trusted render worker finishes after the client leaves, records failures and never duplicates a ready file', async t => {
  const f = await fixture(t), doc = await issued(f);
  await renderPending(f.store, async () => { throw new Error('Synthetic provider failure'); });
  assert.equal(f.store.get('SELECT render FROM documents').render,'failed');
  assert.equal((await f.request(`/api/verify/${doc.reference}`)).status,404);
  await renderPending(f.store,renderEnglishPdf); await renderPending(f.store,renderEnglishPdf);
  assert.equal(f.store.get('SELECT count(*) n FROM files').n,1);
  assert.equal(f.store.get('SELECT render FROM documents').render,'ready');
  deliverPending(f.store); assert.equal((await f.clients.patient('/api/notifications')).body.length,1);
});
