// Synthetic browser acceptance only; never imports or approves real clinic data.
import { mkdirSync, writeFileSync } from 'node:fs';
import { randomBytes } from 'node:crypto';
import { resolve } from 'node:path';
import { Store, id } from '../services/shared_api/store.mjs';
import { createApi } from '../services/shared_api/server.mjs';
import { renderEnglishPdf, startWorkers } from '../services/shared_api/workers.mjs';

const directory = resolve('.tmp', `browser-acceptance-${Date.now()}`);
mkdirSync(directory, { recursive: true });
const store = new Store({ directory: resolve(directory, 'data'), fileKey: randomBytes(32).toString('hex') });
const password = 'Synthetic-Test-Password-2026!';
const patient = store.addUser({ email: 'patient@test.demo', name: 'Synthetic Browser Patient', role: 'patient', password });
const doctor = store.addUser({ email: 'doctor@test.demo', name: 'Synthetic Browser Doctor', role: 'staff', job: 'doctor', password, credentialUntil: Date.now() + 86400000 });
const other = store.addUser({ email: 'other@test.demo', name: 'Unrelated Browser Doctor', role: 'staff', job: 'doctor', password, credentialUntil: Date.now() + 86400000 });
const admin = store.addUser({ email: 'admin@test.demo', name: 'Synthetic Browser Admin', role: 'admin', password });
const visit = id();
store.run('INSERT INTO care VALUES(?,?)', patient, doctor);
store.run("INSERT INTO visits(id,patient,staff,at,status) VALUES(?,?,?,?,'completed')", visit, patient, doctor, Date.now());
store.run("INSERT INTO settings VALUES('clinicName','Synthetic Browser Acceptance Clinic')");
store.run("INSERT INTO settings VALUES('synthetic','true')");
const template = id();
store.run('INSERT INTO templates VALUES(?,?,?,?,?,?,?)', template, 'sickLeaveCertificate', 'en', 'employer',
  '{patientName} attended on {visitDate}. Leave from {startDate} to {endDate}.', 1, 1);
store.audit(admin, 'synthetic.policyApprovedForAcceptanceOnly', template);
writeFileSync('.tmp/task8-browser-fixture.json', JSON.stringify({ directory, patient, doctor, other, admin, visit, template }));
const api = createApi({ store, origins: ['http://localhost:8080'], renderDocument: renderEnglishPdf });
const stop = startWorkers(store, { directory: resolve(directory, 'backups'), key: randomBytes(32).toString('hex'), renderDocument: renderEnglishPdf });
api.listen(8787, '127.0.0.1', () => console.log('Synthetic browser API ready; fixed TEST password in this fixture source.'));
process.once('SIGINT', async () => { await stop(); api.close(() => { store.close(); process.exit(0); }); api.closeIdleConnections(); });
