import { performance } from 'node:perf_hooks';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomBytes } from 'node:crypto';
import { Store, id } from './store.mjs';
import { createApi } from './server.mjs';

test('100 concurrent duplicate writes and stale updates preserve one task and one outcome', async () => {
  const directory = mkdtempSync(join(tmpdir(),'myhealth-load-'));
  const store = new Store({ directory, fileKey: randomBytes(32).toString('hex') });
  const password = 'Synthetic-load-password-2026!', patient = store.addUser({ email:'patient@load.demo',name:'Synthetic Patient',role:'patient',password });
  const doctor = store.addUser({ email:'doctor@load.demo',name:'Synthetic Doctor',role:'staff',job:'doctor',password });
  store.run('INSERT INTO care VALUES(?,?)',patient,doctor);
  const server = createApi({ store }); await new Promise(r => server.listen(0,'127.0.0.1',r));
  const base = `http://127.0.0.1:${server.address().port}`, timings = [];
  const call = async (path, body, token, method='POST') => {
    const started = performance.now();
    const response = await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify(body)});
    const data = await response.json(); timings.push(performance.now()-started); return {status:response.status,body:data};
  };
  try {
    const login = await call('/api/login',{email:'doctor@load.demo',password}); assert.equal(login.status,200);
    const token = login.body.token, input = {patientId:patient,sourceId:'load:one',title:'Synthetic follow-up',kind:'followUpDue',idempotencyKey:id()};
    const writes = await Promise.all(Array.from({length:100},() => call('/api/tasks',input,token)));
    assert.ok(writes.every(w => w.status===200)); assert.equal(new Set(writes.map(w=>w.body.id)).size,1);
    const taskId = writes[0].body.id;
    const updates = await Promise.all(Array.from({length:100},(_,n) => call(`/api/tasks/${taskId}`,{status:'done',outcome:`Synthetic result ${n}`,expectedVersion:1},token,'PATCH')));
    assert.equal(updates.filter(w=>w.status===200).length,1); assert.equal(updates.filter(w=>w.status===409).length,99);
    assert.equal(store.get('SELECT count(*) n FROM tasks').n,1); assert.equal(store.get('SELECT count(*) n FROM task_history').n,1);
    timings.sort((a,b)=>a-b);
    console.log(JSON.stringify({requests:timings.length,p50Ms:timings[Math.floor(timings.length*.5)],p95Ms:timings[Math.floor(timings.length*.95)],
      storage:'local synthetic SQLite',duplicateWrites:100,conflictingUpdates:100}));
  } finally { await new Promise(r => { server.close(r);server.closeAllConnections(); }); store.close(); rmSync(directory,{recursive:true,force:true}); }
});
