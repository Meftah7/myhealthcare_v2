import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {Store,passwordHash} from './store.mjs';
import {provisionSharedDemo,sharedDemoManifest} from './workforce_demo.mjs';
import {workforceOps} from './workforce_ops.mjs';
import {createApi} from './server.mjs';

const password='Synthetic-Workforce-2026!';
function fixture(t){
 const directory=mkdtempSync(join(tmpdir(),'myhealth-workforce-'));let clock=Date.parse('2026-10-15T07:00:00Z');
 const store=new Store({directory,fileKey:'a'.repeat(64),now:()=>clock});
 t.after(()=>{store.close();rmSync(directory,{recursive:true,force:true});});
 const provision=(initialize=false)=>provisionSharedDemo(store,{password,initialize,now:()=>clock});
 const actor=role=>store.get('SELECT * FROM users WHERE job=? ORDER BY email LIMIT 1',role);
 const request=(who,resource,body,method='GET',parameters={})=>workforceOps({store,now:()=>clock,path:'/api/workforce/'+resource,method,url:new URL('http://localhost/?'+new URLSearchParams(parameters)),body,actor:who});
 return {store,provision,actor,request,advance:()=>clock+=1000};
}
test('explicit demo roster is complete, idempotent and preserves existing credentials and status',t=>{
 const f=fixture(t);assert.throws(()=>f.provision(),/synthetic/);f.provision(true);
 const before=sharedDemoManifest(f.store),counts=Object.groupBy(before,r=>r.professionalRole??r.accountType);
 assert.deepEqual(Object.fromEntries(Object.entries(counts).map(([k,v])=>[k,v.length])),{admin:2,dentist:4,doctor:12,nurse:18,pharmacist:4,receptionist:6});
 const nurse=f.actor('nurse'),hash=passwordHash('Custom-Preserved-Password!');
 f.store.run('UPDATE users SET name=?,active=0,password_hash=?,salt=? WHERE id=?','Preserved Name',hash.hash,hash.salt,nurse.id);
 const visits=f.store.get('SELECT COUNT(*) n FROM appointments').n;
 f.provision();f.provision();
 const current=f.store.get('SELECT * FROM users WHERE id=?',nurse.id);assert.equal(current.name,'Preserved Name');assert.equal(current.active,0);assert.equal(current.password_hash,hash.hash);
 assert.equal(sharedDemoManifest(f.store).length,46);assert.equal(f.store.get('SELECT COUNT(*) n FROM appointments').n,visits);
 assert.equal(JSON.stringify(before).includes('password'),false);
});
test('each role can read its real Home, directory and own work without clinical leakage',t=>{
 const f=fixture(t);f.provision(true);
 for(const role of ['doctor','nurse','receptionist','pharmacist','dentist']){
  const actor=f.actor(role),home=f.request(actor,'home');assert.equal(home.role,role);assert.ok(home.stats);assert.ok(f.request(actor,'directory').rows.length===44);
  if(['receptionist','pharmacist'].includes(role))assert.throws(()=>f.request(actor,'intakes'),/Nursing/);
 }
});
test('team conversation membership, payload-bound retry and unread survive another client',t=>{
 const f=fixture(t);f.provision(true);const desk=f.actor('receptionist'),pharmacy=f.actor('pharmacist'),nurse=f.actor('nurse');
 const conversation=f.request(desk,'conversations',{peerId:pharmacy.id},'POST').id;
 const body={conversationId:conversation,body:'Synthetic stock question',idempotencyKey:'team-once'};
 f.request(desk,'messages',body,'POST');f.request(desk,'messages',body,'POST');
 assert.equal(f.request(pharmacy,'conversations').rows[0].unread,1);
 assert.equal(f.request(pharmacy,'thread',undefined,'GET',{id:conversation}).rows.length,1);
 assert.throws(()=>f.request(nurse,'thread',undefined,'GET',{id:conversation}),/membership/);
 assert.throws(()=>f.request(desk,'messages',{...body,body:'changed'},'POST'),/different|reused|match/i);
 f.request(pharmacy,'read',{conversationId:conversation},'POST');assert.equal(f.request(pharmacy,'conversations').rows[0].unread,0);
});
test('nursing observations persist once and cannot complete or sign the clinical encounter',t=>{
 const f=fixture(t);f.provision(true);const nurse=f.actor('nurse'),other=f.store.get("SELECT * FROM users WHERE job='nurse' AND id!=? LIMIT 1",nurse.id);
 const intake=f.request(nurse,'intakes').rows[0];assert.ok(intake);
 const body={id:intake.id,version:intake.version,note:'Synthetic intake',temperature:36.8,pulse:72,oxygen:98,idempotencyKey:'intake-once'};
 assert.throws(()=>f.request(other,'intakes',body,'POST'),/assigned/);
 f.request(nurse,'intakes',body,'POST');f.request(nurse,'intakes',body,'POST');
 assert.equal(f.store.get('SELECT COUNT(*) n FROM vitals WHERE appointment=?',intake.appointment_id).n,1);
 assert.equal(f.store.get('SELECT status FROM appointments WHERE id=?',intake.appointment_id).status,'checkedIn');
 assert.equal(f.store.get('SELECT COUNT(*) n FROM signed_notes WHERE appointment=?',intake.appointment_id).n,0);
 assert.equal(f.store.get('SELECT COUNT(*) n FROM encounter_participants WHERE appointment=? AND staff=?',intake.appointment_id,nurse.id).n,1);
});
test('all 46 stored roster identities authenticate through the real HTTP login service',async t=>{
 const f=fixture(t);f.provision(true);const server=createApi({store:f.store});await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 t.after(async()=>{await new Promise(resolve=>{server.close(resolve);server.closeAllConnections();});});
 const base=`http://127.0.0.1:${server.address().port}`;
 for(const account of sharedDemoManifest(f.store)){
  for(let n=0;n<5;n++)f.advance();
  const response=await fetch(base+'/api/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:account.email,password})});
  const result=await response.json();assert.equal(response.status,200,account.email+': '+JSON.stringify(result));assert.equal(result.user.id,account.id);
 }
});
test('shared home readings remain self-scoped and cannot impersonate clinical observations',t=>{
 const f=fixture(t);f.provision(true);const patient=f.store.get("SELECT * FROM users WHERE role='patient' ORDER BY email LIMIT 1"),other=f.store.get("SELECT * FROM users WHERE role='patient' AND id!=? LIMIT 1",patient.id);
 const body={id:'home-reading-once',patientId:patient.id,temperature:36.7,pulse:70,oxygen:98};
 const first=f.request(patient,'vitals',body,'POST');f.request(patient,'vitals',body,'POST');assert.equal(first.recordedByStaffId,null);assert.equal(f.store.get('SELECT COUNT(*) n FROM vitals').n,1);
 assert.equal(f.request(patient,'vitals',undefined,'GET',{patientId:patient.id}).rows.length,1);
 assert.throws(()=>f.request(other,'vitals',undefined,'GET',{patientId:patient.id}),/denied/);
 assert.throws(()=>f.request(patient,'vitals',{...body,id:'forged',appointmentId:'visit'},'POST'),/clinic encounter/);
});
