import {fields,id,requireThat,text} from './store.mjs';

const clinical=['doctor','dentist','nurse'];
export function dutyOps({store,now,path,method,url,body,actor}){
 if(!path.startsWith('/api/duty/'))return undefined;
 requireThat(actor.role==='staff'&&[...clinical,'pharmacist','receptionist'].includes(actor.job),403,'Validated staff access required.');
 const resource=path.slice('/api/duty/'.length);
 const mine=()=>store.all("SELECT * FROM tasks WHERE owner=? OR (coverage_staff=? AND coverage_until>?) ORDER BY created DESC,id",actor.id,actor.id,now());
 if(resource==='handover'&&method==='GET')return {
  tasks:mine(),
  offers:store.all("SELECT o.id,o.sender,u.name AS sender_name,o.recipient,o.expires,o.status,o.created,CASE WHEN o.sender=? THEN o.reason ELSE NULL END AS reason,json_array_length(o.tasks) AS task_count FROM duty_offers o JOIN users u ON u.id=o.sender WHERE o.sender=? OR o.recipient=? ORDER BY o.created DESC",actor.id,actor.id,actor.id),
  recipients:store.all("SELECT id,name,job FROM users WHERE role='staff' AND active=1 AND id!=? AND job IN ('doctor','dentist','nurse','receptionist','pharmacist') ORDER BY name",actor.id),
 };
 if(resource==='offers'&&method==='POST'){
  fields(body,['recipient','tasks','reason','expires','idempotencyKey']);const recipient=store.get("SELECT * FROM users WHERE id=? AND active=1 AND role='staff'",text(body.recipient,128));
  const expires=Date.parse(body.expires),reason=text(body.reason,2000);requireThat(recipient&&recipient.id!==actor.id,403,'Choose another active staff member.');requireThat(expires>now()&&expires<=now()+72*3600000,400,'Choose a cover period of up to 72 hours.');requireThat(Array.isArray(body.tasks)&&body.tasks.length>0&&body.tasks.length<=100,400,'Choose 1–100 owned tasks.');
  return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
   const tasks=body.tasks.map(input=>{fields(input,['id','version']);const task=store.get('SELECT * FROM tasks WHERE id=?',text(input.id,128));requireThat(task&&task.owner===actor.id,403,'Only the owner can offer work.');requireThat(task.version===input.version&&!['done','dismissed'].includes(task.status),409,'Work changed. Reload before offering.');requireThat(!task.patient||clinical.includes(recipient.job),403,'Clinical work requires a clinical recipient.');return {id:task.id,version:task.version};});
   requireThat(new Set(tasks.map(t=>t.id)).size===tasks.length,400,'Choose each task once.');const key=id();store.run('INSERT INTO duty_offers(id,sender,recipient,tasks,reason,expires,created) VALUES(?,?,?,?,?,?,?)',key,actor.id,recipient.id,JSON.stringify(tasks),reason,expires,now());store.audit(actor.id,'task.coverOffered',key);return {id:key};
  }));
 }
 if(resource==='decide'&&method==='POST'){
  fields(body,['id','accept','idempotencyKey']);requireThat(typeof body.accept==='boolean');
  return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
   const offer=store.get('SELECT * FROM duty_offers WHERE id=?',text(body.id,128));requireThat(offer&&offer.recipient===actor.id,403,'Only the named recipient can decide.');requireThat(offer.status==='pending'&&offer.expires>now(),409,'Offer expired or was already answered.');
   if(body.accept){
    requireThat(store.get('SELECT active FROM users WHERE id=?',offer.sender)?.active===1,403,'The sender is no longer active.');
    for(const input of JSON.parse(offer.tasks)){
     const task=store.get('SELECT * FROM tasks WHERE id=?',input.id);requireThat(task?.owner===offer.sender&&task.version===input.version&&!['done','dismissed'].includes(task.status),409,'An offered task changed; nothing was transferred.');requireThat(!task.patient||clinical.includes(actor.job),403,'Clinical work requires clinical access.');
     const updated=store.run('UPDATE tasks SET coverage_staff=?,coverage_until=?,version=version+1 WHERE id=? AND version=?',actor.id,offer.expires,task.id,input.version);requireThat(updated.changes===1,409,'Task changed.');
     store.run('INSERT INTO task_history VALUES(?,?,?,?,?,?,?)',id(),task.id,actor.id,now(),JSON.stringify(task),JSON.stringify(store.get('SELECT * FROM tasks WHERE id=?',task.id)),offer.reason);
    }
   }
   store.run('UPDATE duty_offers SET status=?,decided=? WHERE id=?',body.accept?'accepted':'declined',now(),offer.id);store.audit(actor.id,body.accept?'task.coverAccepted':'task.coverDeclined',offer.id);return {ok:true};
  }));
 }
 if(resource==='time-off'&&method==='GET')return {rows:store.all('SELECT * FROM duty_time_off WHERE staff=? ORDER BY start DESC,id',actor.id),conflicts:store.all("SELECT a.id,a.patient,a.start,a.end,a.status FROM appointments a JOIN duty_time_off d ON d.staff=a.staff AND d.active=1 AND a.start<d.end AND a.end>d.start WHERE a.staff=? AND a.status IN ('booked','checkedIn','inProgress') ORDER BY a.start",actor.id)};
 if(resource==='time-off'&&method==='POST'){
  fields(body,['start','end','reason','idempotencyKey']);const start=Date.parse(body.start),end=Date.parse(body.end),reason=text(body.reason,2000);requireThat(Number.isFinite(start)&&Number.isFinite(end)&&start>=now()&&end>start&&end-start<=90*86400000,400,'Choose a future period of up to 90 days.');
  return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{const key=id();store.run('INSERT INTO duty_time_off(id,staff,start,end,reason,created) VALUES(?,?,?,?,?,?)',key,actor.id,start,end,reason,now());store.run('INSERT INTO schedule_exceptions(id,staff,start,end) VALUES(?,?,?,?)',key,actor.id,start,end);store.audit(actor.id,'schedule.timeOffRecorded',key);return {id:key};}));
 }
 if(resource==='cancel-time-off'&&method==='POST'){
  fields(body,['id','reason']);text(body.reason,2000);return store.transaction(()=>{const leave=store.get('SELECT * FROM duty_time_off WHERE id=? AND staff=?',text(body.id,128),actor.id);requireThat(leave?.active===1,409,'Time off is no longer active.');store.run('UPDATE duty_time_off SET active=0 WHERE id=?',leave.id);store.run('DELETE FROM schedule_exceptions WHERE id=? AND staff=?',leave.id,actor.id);store.audit(actor.id,'schedule.timeOffCancelled',leave.id);return {ok:true};});
 }
 return undefined;
}
