import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {Store} from './store.mjs';
import {workspaceOps,clinicBounds,availableDoctorSlots} from './workspace_ops.mjs';

function fixture(t){
  const directory=mkdtempSync(join(tmpdir(),'myhealth-workspace-')),now=Date.parse('2026-10-15T07:00:00Z');
  const store=new Store({directory,fileKey:'a'.repeat(64),now:()=>now});
  t.after(()=>{store.close();rmSync(directory,{recursive:true,force:true});});
  const add=(name,role,job)=>store.addUser({email:name+'@test.demo',name,role,job:job??null,password:'Synthetic-Password-2026!'});
  const doctor=add('doctor','staff','doctor'),nurse=add('nurse','staff','nurse'),other=add('otherDoctor','staff','doctor'),patient=add('patient','patient'),stranger=add('stranger','patient'),admin=add('admin','admin');
  const actor=id=>({...store.get('SELECT * FROM users WHERE id=?',id),session:{reauthed:now}});
  const request=(who,resource,parameters={},body,method='GET')=>workspaceOps({store,now:()=>now,path:'/api/workspace/'+resource,method,url:new URL('http://localhost/?'+new URLSearchParams(parameters)),body,actor:actor(who)});
  const visit=(id,p,s,status='completed',time=now)=>{store.run('INSERT INTO appointments(id,patient,staff,start,end,status,booked_by,completed_at) VALUES(?,?,?,?,?,?,?,?)',id,p,s,time,time+1200000,status,p,status==='completed'?time:null);};
  return {store,now,doctor,nurse,other,patient,stranger,admin,request,visit,actor};
}
test('clinic boundaries are Bahrain UTC+3 and reject invalid dates',()=>{assert.deepEqual(clinicBounds('2026-10-01'),[Date.parse('2026-09-30T21:00Z'),Date.parse('2026-10-01T21:00Z')]);assert.throws(()=>clinicBounds('2026-02-30'));});
test('history excludes upcoming/other clinicians before paging and deduplicates',t=>{
  const f=fixture(t);f.visit('a',f.patient,f.doctor);f.visit('b',f.patient,f.doctor);f.visit('c',f.stranger,f.other);f.visit('d',f.stranger,f.doctor,'booked');
  const d=f.request(f.doctor,'history',{limit:1});assert.equal(d.stats.total,1);assert.equal(d.total,1);assert.equal(d.rows[0].id,f.patient);assert.equal(d.stats.month,1);
  assert.equal(f.request(f.doctor,'history',{query:f.stranger}).total,0);assert.throws(()=>f.request(f.admin,'history'),/Clinical staff/);
});
test('nurse participation is explicit, scoped, idempotent and only completed visits enter history',t=>{
  const f=fixture(t);f.visit('a',f.patient,f.doctor);f.visit('b',f.stranger,f.doctor);f.store.run('INSERT INTO care VALUES(?,?)',f.patient,f.nurse);
  assert.equal(f.request(f.nurse,'history').total,0);
  f.request(f.nurse,'participation',{}, {appointmentId:'a'},'POST');f.request(f.nurse,'participation',{}, {appointmentId:'a'},'POST');
  assert.equal(f.request(f.nurse,'history').total,1);assert.equal(f.store.get('SELECT COUNT(*) n FROM encounter_participants').n,1);
  assert.throws(()=>f.request(f.nurse,'participation',{}, {appointmentId:'b'},'POST'),/denied/);
});
test('gender excludes undisclosed, demand uses scheduled hours, room total starts unconfigured',t=>{
  const f=fixture(t);f.store.run("UPDATE users SET gender='male' WHERE id=?",f.patient);f.visit('a',f.patient,f.doctor);f.visit('b',f.stranger,f.doctor);f.visit('c',f.patient,f.doctor,'cancelled');
  const d=f.request(f.admin,'overview',{day:'2026-10-15',days:7});assert.equal(d.stats.roomsConfigured,false);assert.equal(d.gender.find(r=>r.gender==='male').n,1);assert.equal(d.gender.find(r=>r.gender===null).n,1);assert.equal(d.hours.find(r=>r.hour===10).n,2);
});
test('doctor availability uses role, schedule, exceptions and bookings',t=>{
  const f=fixture(t);f.store.run('INSERT INTO schedules VALUES(?,?,?,?,?)',f.doctor,4,600,720,20);f.store.run('INSERT INTO schedule_exceptions VALUES(?,?,?,?)','leave',f.doctor,f.now+20*60000,f.now+40*60000);
  f.visit('busy',f.patient,f.doctor,'booked',f.now+40*60000);
  const slots=availableDoctorSlots(f.store,f.doctor,'2026-10-15',f.now);assert.equal(slots[0].start,'2026-10-15T08:00:00.000Z');assert.deepEqual(availableDoctorSlots(f.store,f.nurse,'2026-10-15',f.now),[]);
});
test('room saves are versioned; feedback submission/filter data and resolve attribution persist',t=>{
  const f=fixture(t);f.request(f.admin,'rooms',{}, {id:null,label:'A-02',departmentId:null,enabled:true,version:0},'POST');const room=f.request(f.admin,'rooms').rows[0];
  f.request(f.admin,'rooms',{}, {id:room.id,label:'A-02',departmentId:null,enabled:false,version:1},'POST');assert.throws(()=>f.request(f.admin,'rooms',{}, {id:room.id,label:'Stale',departmentId:null,enabled:true,version:1},'POST'),/changed/);
  f.request(f.patient,'feedback-submit',{}, {category:'generalFeedback',message:'Synthetic feedback'},'POST');const fb=f.request(f.admin,'feedback').rows[0];assert.equal(fb.reporter_role,'patient');f.request(f.admin,'feedback',{}, {id:fb.id,status:'resolved',version:fb.version},'POST');assert.equal(f.request(f.admin,'feedback').rows[0].handler_name,'admin');
});
test('receipts/refunds are integer fils, idempotent and cannot over-refund',t=>{
  const f=fixture(t);f.store.run("INSERT INTO invoices(id,patient,description,amount_fils,paid_fils,status,created) VALUES('invoice',?,'Consultation',12345,12345,'paid',?)",f.patient,f.now);
  f.store.run("INSERT INTO payments VALUES('payment','invoice',12345,'desk',?,?)",f.admin,f.now);
  const input={paymentId:'payment',amountFils:2345,reason:'Synthetic partial desk refund',idempotencyKey:'refund-once'};
  const one=f.request(f.admin,'refunds',{},input,'POST'),two=f.request(f.admin,'refunds',{},input,'POST');assert.equal(one.id,two.id);
  assert.throws(()=>f.request(f.admin,'refunds',{}, {...input,amountFils:10001,idempotencyKey:'over-refund'},'POST'),/exceeds/);
  const report=f.request(f.admin,'overview',{day:'2026-10-15',revenueDays:7});const today=report.revenue.at(-1);assert.equal(today.payments,12345);assert.equal(today.refunds,2345);assert.equal(today.payments-today.refunds,10000);
  assert.throws(()=>f.request(f.patient,'overview'),/Administrator/);
});
test('bulk deactivation protects last admin and rolls back the whole selection',t=>{
  const f=fixture(t);const accounts=[f.patient,f.admin].map(id=>({id,version:1}));
  assert.throws(()=>f.request(f.admin,'users',{}, {accounts,active:false},'POST'),/last administrator/);
  assert.equal(f.store.get('SELECT active FROM users WHERE id=?',f.patient).active,1);assert.equal(f.store.get('SELECT auth_version FROM users WHERE id=?',f.patient).auth_version,1);
  f.visit('upcoming',f.stranger,f.doctor,'booked');assert.throws(()=>f.request(f.admin,'users',{}, {accounts:[{id:f.doctor,version:1}],active:false},'POST'),/bookings/);
});
test('referral metrics count request creation, not follow-up task updates',t=>{
  const f=fixture(t);f.visit('visit',f.patient,f.doctor,'inProgress');f.store.run('INSERT INTO care VALUES(?,?)',f.patient,f.doctor);
  const input={patientId:f.patient,appointmentId:'visit',reason:'Specialist assessment',idempotencyKey:'referral-once'};
  const first=f.request(f.doctor,'referrals',{},input,'POST');f.request(f.doctor,'referrals',{},input,'POST');assert.equal(f.request(f.admin,'overview',{day:'2026-10-15'}).stats.referrals,1);
  f.store.run("UPDATE referral_requests SET status='closed',version=version+1 WHERE id=?",first.id);assert.equal(f.request(f.admin,'overview',{day:'2026-10-15'}).stats.referrals,1);
});
