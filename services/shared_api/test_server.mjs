// Test harness: a throwaway shared server with synthetic demo data on a
// random loopback port. Prints {"port":N} once listening; exits when stdin
// closes. Used by the Flutter end-to-end shared-mode test only.
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { Store, id } from './store.mjs';
import { createApi } from './server.mjs';

const password = process.argv[2] ?? 'Synthetic-Test-Password-2026!';
const directory = mkdtempSync(join(tmpdir(), 'myhealth-e2e-'));
const store = new Store({ directory: join(directory, 'data'), fileKey: randomBytes(32).toString('hex') });
store.transaction(() => {
  const dept = id();
  store.run('INSERT INTO departments VALUES(?,?,?)', dept, 'Family Medicine', null);
  const patient = store.addUser({ email: 'patient@shared.demo', name: 'Synthetic Patient', role: 'patient', password });
  const doctor = store.addUser({ email: 'doctor@shared.demo', name: 'Synthetic Doctor', role: 'staff', job: 'doctor', password });
  store.addUser({ email: 'pharmacy@shared.demo', name: 'Synthetic Pharmacist', role: 'staff', job: 'pharmacist', password });
  store.addUser({ email: 'reception@shared.demo', name: 'Synthetic Receptionist', role: 'staff', job: 'receptionist', password });
  store.addUser({ email: 'admin@shared.demo', name: 'Synthetic Admin', role: 'admin', password });
  store.run('UPDATE users SET department=? WHERE id=?', dept, doctor);
  for (let weekday = 1; weekday <= 7; weekday++) {
    store.run('INSERT INTO schedules(staff,weekday,start_min,end_min) VALUES(?,?,?,?)', doctor, weekday, 0, 1440);
  }
  void patient;
});
const server = createApi({ store, origins: [] });
server.listen(0, '127.0.0.1', () => {
  process.stdout.write(JSON.stringify({ port: server.address().port }) + '\n');
});
process.stdin.on('end', () => {
  server.close(); server.closeAllConnections(); store.close();
  rmSync(directory, { recursive: true, force: true });
  process.exit(0);
});
process.stdin.resume();
