import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {Store} from './store.mjs';
import {dutyOps} from './duty_ops.mjs';
function fixture(t){
 const directory=mkdtempSync(join(tmpdir(),'myhealth-duty-'));let clock=Date.parse('2026-10-16T06:00:00Z');const store=new Store({directory,fileKey:'a'.repeat(64),now:()=>clock});t.after(()=>{store.close();rmSync(directory,{recursive:true,force:true});});
 const add=(name,role,job)=>store.addUser({name,email:name+'@test.demo',role,job,password:'Synthetic-Duty-Password!'}),doctor=add('doctor','staff','doctor'),nurse=add('nurse','staff','nurse'),pharmacy=add('pharmacy','staff','pharmacist'),patient=add('patient','patient');
 store.run('INSERT INTO care VALUES(?,?)',patient,doctor);store.run("INSERT INTO tasks(id,owner,patient,source,title,kind,created) VALUES('task',?,?,'source','Review synthetic result','resultReview',?)",doctor,patient,clock);
 const request=(who,resource,body,method='GET')=>dutyOps({store,now:()=>clock,path:'/api/duty/'+resource,method,url:new URL('http://localhost'),body,actor:store.get('SELECT * FROM users WHERE id=?',who)});
 return {store,doctor,nurse,pharmacy,patient,request,now:()=>clock,advance:ms=>clock+=ms};
}
test('cover requires explicit acceptance; recipient sees no clinical details before it and access expires',t=>{
 const f=fixture(t);const input={recipient:f.nurse,tasks:[{id:'task',version:1}],reason:'Synthetic handover',expires:new Date(f.now()+60000).toISOString(),idempotencyKey:'offer-once'};
 const one=f.request(f.doctor,'offers',input,'POST'),two=f.request(f.doctor,'offers',input,'POST');assert.equal(one.id,two.id);
 const pending=f.request(f.nurse,'handover');assert.equal(pending.tasks.length,0);assert.equal(pending.offers[0].task_count,1);assert.equal(JSON.stringify(pending.offers).includes(f.patient),false);
 assert.throws(()=>f.store.patientAccess(f.store.get('SELECT * FROM users WHERE id=?',f.nurse),f.patient),/denied/);
 const accepted={id:one.id,accept:true,idempotencyKey:'accept-once'};f.request(f.nurse,'decide',accepted,'POST');f.request(f.nurse,'decide',accepted,'POST');
 const task=f.store.get("SELECT * FROM tasks WHERE id='task'");assert.equal(task.owner,f.doctor);assert.equal(task.coverage_staff,f.nurse);assert.equal(task.version,2);
 assert.ok(f.store.patientAccess(f.store.get('SELECT * FROM users WHERE id=?',f.nurse),f.patient));f.advance(60001);
 assert.throws(()=>f.store.patientAccess(f.store.get('SELECT * FROM users WHERE id=?',f.nurse),f.patient),/denied/);
});
test('nonclinical recipients cannot accept clinical work; stale bundles roll back without transferring anything',t=>{
 const f=fixture(t),body={recipient:f.pharmacy,tasks:[{id:'task',version:1}],reason:'Synthetic cover',expires:new Date(f.now()+60000).toISOString(),idempotencyKey:'bad-cover'};
 assert.throws(()=>f.request(f.doctor,'offers',body,'POST'),/Clinical/);
 const offer=f.request(f.doctor,'offers',{...body,recipient:f.nurse,idempotencyKey:'good-cover'},'POST');f.store.run("UPDATE tasks SET version=version+1 WHERE id='task'");
 assert.throws(()=>f.request(f.nurse,'decide',{id:offer.id,accept:true,idempotencyKey:'stale'},'POST'),/changed/);assert.equal(f.store.get("SELECT coverage_staff FROM tasks WHERE id='task'").coverage_staff,null);
});
test('time off is stored once and only the owner can cancel it',t=>{
 const f=fixture(t),body={start:new Date(f.now()+3600000).toISOString(),end:new Date(f.now()+7200000).toISOString(),reason:'Synthetic time off',idempotencyKey:'leave-once'};
 const leave=f.request(f.doctor,'time-off',body,'POST');f.request(f.doctor,'time-off',body,'POST');assert.equal(f.request(f.doctor,'time-off').rows.length,1);
 assert.throws(()=>f.request(f.nurse,'cancel-time-off',{id:leave.id,reason:'Wrong actor'},'POST'),/active/);
 f.request(f.doctor,'cancel-time-off',{id:leave.id,reason:'Changed plan'},'POST');assert.equal(f.store.get('SELECT COUNT(*) n FROM schedule_exceptions WHERE id=?',leave.id).n,0);
});
