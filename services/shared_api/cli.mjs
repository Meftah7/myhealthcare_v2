import {provisionSharedDemo,sharedDemoManifest} from './workforce_demo.mjs';
import { resolve } from 'node:path';
import { geminiReportChat, geminiReportExplainer } from './ai.mjs';
import { Store, requireThat } from './store.mjs';
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
    } else if (command === 'init-demo' || command === 'repair-demo') {
      const result=provisionSharedDemo(store,{password:process.env.MYHEALTH_DEMO_PASSWORD,initialize:command==='init-demo'});
      console.log(JSON.stringify(result));
    } else if (command === 'demo-manifest') {
      console.log(JSON.stringify(sharedDemoManifest(store)));
    } else if (command === 'backup') {
      console.log(await encryptedBackup(store, { directory: process.env.MYHEALTH_BACKUP_DIR, key: process.env.MYHEALTH_BACKUP_KEY }));
    } else if (command === 'serve') {
      requireThat(process.env.MYHEALTH_BACKUP_DIR && /^[a-f0-9]{64}$/.test(process.env.MYHEALTH_BACKUP_KEY ?? ''), 500, 'Configure encrypted scheduled backups.');
      requireThat(store.get('SELECT count(*) n FROM users').n > 0, 500, 'Initialize server accounts offline first.');
      if(store.get("SELECT value FROM settings WHERE key='synthetic'")?.value==='true' && process.env.MYHEALTH_DEMO_PASSWORD) provisionSharedDemo(store,{password:process.env.MYHEALTH_DEMO_PASSWORD});
      const renderDocument = process.env.MYHEALTH_PDF_RENDERER === 'english' ? renderEnglishPdf : undefined;
      // Report explanation is optional: only with a server-held provider key.
      const reportExplainer = process.env.MYHEALTH_AI_KEY
        ? geminiReportExplainer({ apiKey: process.env.MYHEALTH_AI_KEY, model: process.env.MYHEALTH_AI_MODEL || undefined })
        : undefined;
      const reportChat = process.env.MYHEALTH_AI_KEY
        ? geminiReportChat({ apiKey: process.env.MYHEALTH_AI_KEY, model: process.env.MYHEALTH_AI_MODEL || undefined })
        : undefined;
      const server = createApi({ store, origins: (process.env.MYHEALTH_ORIGINS ?? '').split(',').filter(Boolean), renderDocument, reportExplainer, reportChat });
      const stopWorkers = startWorkers(store, { directory: process.env.MYHEALTH_BACKUP_DIR, key: process.env.MYHEALTH_BACKUP_KEY, renderDocument });
      const port = Number(process.env.PORT ?? 8787);
      await new Promise(resolveStarted => server.listen(port, '127.0.0.1', resolveStarted));
      console.log(`Shared API listening on loopback port ${port}. Use an HTTPS reverse proxy for other devices.`);
      await new Promise(done => {
        let stopping = false;
        const stop = async () => { if (stopping) return; stopping = true; await stopWorkers(); server.close(done); server.closeIdleConnections(); };
        process.once('SIGINT', stop); process.once('SIGTERM', stop);
      });
    } else throw new Error('Use init-admin, init-demo, repair-demo, demo-manifest, serve, backup or restore.');
  } finally { store.close(); }
}
