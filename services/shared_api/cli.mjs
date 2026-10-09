import { resolve } from 'node:path';
import { Store, id, requireThat } from './store.mjs';
import { createApi } from './server.mjs';
import { encryptedBackup, restoreBackup, renderEnglishPdf, startWorkers } from './workers.mjs';

const command = process.argv[2], directory = resolve(process.env.MYHEALTH_DATA_DIR ?? './private-data');
if (command === 'restore') {
  // This key is provided ONLY to the offline operator process.
  console.log(JSON.stringify(restoreBackup({ archive: process.argv[3], directory: process.argv[4], key: process.env.MYHEALTH_RESTORE_KEY })));
} else {
  const store = new Store({ directory, fileKey: process.env.MYHEALTH_FILE_KEY });
  try {
    if (command === 'init-admin') {
      requireThat(store.get('SELECT count(*) n FROM users').n === 0, 409, 'Initialize only an empty database.');
      store.addUser({ email: process.env.MYHEALTH_ADMIN_EMAIL, name: process.env.MYHEALTH_ADMIN_NAME,
        role: 'admin', password: process.env.MYHEALTH_ADMIN_PASSWORD });
      console.log('Administrator initialized offline. Provision clinic users and verified credentials before real use.');
    } else if (command === 'init-demo') {
      requireThat(store.get('SELECT count(*) n FROM users').n === 0, 409, 'Initialize only an empty synthetic database.');
      const password = process.env.MYHEALTH_DEMO_PASSWORD; requireThat(password?.length >= 12);
      store.transaction(() => {
        const patient = store.addUser({ email: 'patient@shared.demo', name: 'Synthetic Patient', role: 'patient', password });
        const doctor = store.addUser({ email: 'doctor@shared.demo', name: 'Synthetic Doctor', role: 'staff', job: 'doctor',
          credentialUntil: Date.now() + 30 * 86400000, password });
        const nurse = store.addUser({ email: 'nurse@shared.demo', name: 'Synthetic Nurse', role: 'staff', job: 'nurse', password });
        const admin = store.addUser({ email: 'admin@shared.demo', name: 'Synthetic Admin', role: 'admin', password });
        store.run('INSERT INTO care VALUES(?,?)', patient, doctor); store.run('INSERT INTO care VALUES(?,?)', patient, nurse);
        store.run("INSERT INTO visits(id,patient,staff,at,status) VALUES(?,?,?,?,'completed')", id(), patient, doctor, Date.now());
        store.run("INSERT INTO settings VALUES('clinicName','Synthetic Shared Demo Clinic')");
        store.run("INSERT INTO settings VALUES('synthetic','true')");
        store.audit(admin, 'synthetic.initialized', patient);
      });
      console.log('Synthetic shared accounts created. Document policies remain unapproved.');
    } else if (command === 'backup') {
      console.log(await encryptedBackup(store, { directory: process.env.MYHEALTH_BACKUP_DIR, key: process.env.MYHEALTH_BACKUP_KEY }));
    } else if (command === 'serve') {
      requireThat(process.env.MYHEALTH_BACKUP_DIR && /^[a-f0-9]{64}$/.test(process.env.MYHEALTH_BACKUP_KEY ?? ''), 500, 'Configure encrypted scheduled backups.');
      requireThat(store.get('SELECT count(*) n FROM users').n > 0, 500, 'Initialize server accounts offline first.');
      const renderDocument = process.env.MYHEALTH_PDF_RENDERER === 'english' ? renderEnglishPdf : undefined;
      const server = createApi({ store, origins: (process.env.MYHEALTH_ORIGINS ?? '').split(',').filter(Boolean), renderDocument });
      const stopWorkers = startWorkers(store, { directory: process.env.MYHEALTH_BACKUP_DIR, key: process.env.MYHEALTH_BACKUP_KEY, renderDocument });
      const port = Number(process.env.PORT ?? 8787);
      await new Promise(resolveStarted => server.listen(port, '127.0.0.1', resolveStarted));
      console.log(`Shared API listening on loopback port ${port}. Use an HTTPS reverse proxy for other devices.`);
      await new Promise(done => {
        let stopping = false;
        const stop = async () => { if (stopping) return; stopping = true; await stopWorkers(); server.close(done); server.closeIdleConnections(); };
        process.once('SIGINT', stop); process.once('SIGTERM', stop);
      });
    } else throw new Error('Use init-admin, init-demo, serve, backup or restore.');
  } finally { store.close(); }
}
