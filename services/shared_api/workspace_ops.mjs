import { fields, id, requireThat, text } from './store.mjs';

export function clinicBounds(day) {
  requireThat(typeof day === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(day),400,'Use YYYY-MM-DD.');
  const wall=Date.parse(day+'T00:00:00Z');
  requireThat(Number.isFinite(wall)&&new Date(wall).toISOString().slice(0,10)===day,400,'Invalid clinic day.');
  return [wall-10800000,wall-10800000+86400000];
}
const clinicDay = instant => new Date(instant+10800000).toISOString().slice(0,10);
export function availableDoctorSlots(store,staffId,day,now) {
  const [midnight,end]=clinicBounds(day),u=store.get("SELECT * FROM users WHERE id=? AND role='staff' AND active=1",staffId);
  if(!u||!['doctor','dentist'].includes(u.job))return [];
  const weekday=((new Date(midnight+10800000).getUTCDay()+6)%7)+1;
  const s=store.get('SELECT * FROM schedules WHERE staff=? AND weekday=?',staffId,weekday);
  if(!s||s.slot_min<1)return [];
  const taken=store.all("SELECT start,end FROM appointments WHERE staff=? AND start<? AND end>? AND status NOT IN ('cancelled','noShow')",staffId,end,midnight);
  const exceptions=store.all('SELECT start,end FROM schedule_exceptions WHERE staff=? AND start<? AND end>?',staffId,end,midnight);
  const result=[];
  for(let minute=s.start_min;minute+s.slot_min<=s.end_min;minute+=s.slot_min){
    const start=midnight+minute*60000,finish=start+s.slot_min*60000;
    if(start>now&&!taken.some(a=>a.start<finish&&a.end>start)&&!exceptions.some(a=>a.start<finish&&a.end>start))result.push({staffId,start:new Date(start).toISOString(),end:new Date(finish).toISOString()});
  }
  return result;
}
const seconds = n => n==null?null:Math.floor(n/1000);
const safeFeedback = r => ({...r,created_at:seconds(r.created),handled_at:seconds(r.handled),reporter_name:r.reporter_name,reporter_role:r.reporter_role});

export function workspaceOps({store,now,path,method,url,body,actor}) {
  if(!path.startsWith('/api/workspace/'))return undefined;
  const resource=path.slice('/api/workspace/'.length);
  const count=(sql,...args)=>Number(Object.values(store.get(sql,...args))[0]);
  const isClinical=actor.role==='staff'&&['doctor','dentist','nurse'].includes(actor.job);
  const admin=()=>requireThat(actor.role==='admin',403,'Administrator access required.');
  if(resource==='history'&&method==='GET'){
    requireThat(isClinical,403,'Clinical staff access required.');
    const own=actor.job==='nurse'?'0':'a.staff=?',args=[...(actor.job==='nurse'?[]:[actor.id]),actor.id];
    const scope=`a.status='completed' AND (${own} OR EXISTS(SELECT 1 FROM encounter_participants ep WHERE ep.appointment=a.id AND ep.staff=?))`;
    const completed='COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment=a.id))';
    const base=`SELECT u.id,u.name AS full_name,u.national_id,u.gender,u.dob,u.conditions AS chronic_conditions,
      MAX(COALESCE(${completed},a.end))/1000 AS last_visit,MAX(CASE WHEN ${completed} IS NULL THEN 1 ELSE 0 END) AS legacy_completion,
      EXISTS(SELECT 1 FROM tasks t WHERE t.patient=u.id AND t.kind='resultReview' AND t.priority='urgent' AND t.status NOT IN ('done','dismissed')) AS critical,
      EXISTS(SELECT 1 FROM tasks t WHERE t.patient=u.id AND t.kind='followUpDue' AND t.status NOT IN ('done','dismissed')) AS follow_up
      FROM appointments a JOIN users u ON u.id=a.patient WHERE ${scope} GROUP BY u.id`;
    const today=clinicDay(now()),[year,month]=today.split('-').map(Number);
    const first=Date.UTC(year,month-1,1)-10800000,next=Date.UTC(year,month,1)-10800000;
    const stats={total:count(`SELECT COUNT(*) FROM (${base})`,...args),critical:count(`SELECT COUNT(*) FROM (${base}) WHERE critical=1`,...args),followUp:count(`SELECT COUNT(*) FROM (${base}) WHERE follow_up=1`,...args),month:count(`SELECT COUNT(DISTINCT a.patient) FROM appointments a WHERE ${scope} AND ${completed}>=? AND ${completed}<?`,...args,first,next)};
    const [todayStart,todayEnd]=clinicBounds(today);
    stats.appointmentsToday=count('SELECT COUNT(*) FROM appointments WHERE staff=? AND start>=? AND start<?',actor.id,todayStart,todayEnd);
    stats.completedToday=count(`SELECT COUNT(*) FROM appointments a WHERE ${scope} AND ${completed}>=? AND ${completed}<?`,...args,todayStart,todayEnd);
    const q='%'+(url.searchParams.get('query')??'').trim().toLowerCase()+'%',filter=url.searchParams.get('filter');
    const where=`(lower(full_name) LIKE ? OR lower(id) LIKE ? OR COALESCE(national_id,'') LIKE ? OR lower(chronic_conditions) LIKE ?)${filter==='critical'?' AND critical=1':filter==='followUp'?' AND follow_up=1':''}`;
    const limit=Number(url.searchParams.get('limit')??50),offset=Number(url.searchParams.get('offset')??0);
    requireThat(Number.isInteger(limit)&&limit>0&&limit<=200&&Number.isInteger(offset)&&offset>=0,400,'Invalid page.');
    return {stats,total:count(`SELECT COUNT(*) FROM (${base}) WHERE ${where}`,...args,q,q,q,q),rows:store.all(`SELECT * FROM (${base}) WHERE ${where} ORDER BY full_name,id LIMIT ? OFFSET ?`,...args,q,q,q,q,limit,offset),nurse:actor.job==='nurse',criticalDefinition:'Unresolved urgent clinical result-review task; appointment no-show prediction is excluded.'};
  }
  if(resource==='participation'&&method==='POST'){
    fields(body,['appointmentId']);requireThat(isClinical,403,'Clinical staff access required.');
    const a=store.get('SELECT * FROM appointments WHERE id=?',text(body.appointmentId,128));requireThat(a,404,'Visit unavailable.');
    store.patientAccess(actor,a.patient);requireThat(['inProgress','completed'].includes(a.status),400,'Visit must be active or completed.');
    store.transaction(()=>{store.run('INSERT OR IGNORE INTO encounter_participants VALUES(?,?,?,?)',a.id,actor.id,now(),actor.id);store.audit(actor.id,'encounter.participated',a.id,{patient:a.patient});});return {ok:true};
  }
  if(resource==='feedback-submit'&&method==='POST'){
    fields(body,['category','message']);requireThat(['bug','featureRequest','generalFeedback','complaint'].includes(body.category));
    const feedbackId=id();store.transaction(()=>{store.run('INSERT INTO feedback(id,reporter,category,message,created) VALUES(?,?,?,?,?)',feedbackId,actor.id,body.category,text(body.message,8000),now());store.audit(actor.id,'feedback.submitted',feedbackId);});return {ok:true};
  }
  if(resource==='referrals'&&method==='POST'){
    fields(body,['patientId','appointmentId','reason','idempotencyKey']);requireThat(isClinical&&['doctor','dentist'].includes(actor.job),403,'Doctor or dentist access required.');
    const patientId=text(body.patientId,128);store.patientAccess(actor,patientId);const appointmentId=body.appointmentId??null;
    if(appointmentId){const a=store.get('SELECT * FROM appointments WHERE id=?',text(appointmentId,128));requireThat(a&&a.patient===patientId&&a.staff===actor.id,403,'Visit access denied.');}
    return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{const referralId=id();store.run('INSERT INTO referral_requests(id,patient,appointment,requested_by,reason,created) VALUES(?,?,?,?,?,?)',referralId,patientId,appointmentId,actor.id,text(body.reason,2000),now());store.audit(actor.id,'referral.created',referralId);return store.get('SELECT * FROM referral_requests WHERE id=?',referralId);}));
  }
  if(resource==='referrals'&&method==='GET'){
    const patient=url.searchParams.get('patientId'),appointment=url.searchParams.get('appointmentId');
    if(actor.role!=='admin'){requireThat(isClinical,403);if(patient)store.patientAccess(actor,patient);else requireThat(appointment,400,'Choose a visit or patient.');}
    const result=store.all(`SELECT * FROM referral_requests WHERE 1=1 ${patient?'AND patient=?':''} ${appointment?'AND appointment=?':''} ORDER BY created DESC,id`,...(patient?[patient]:[]),...(appointment?[appointment]:[]));
    if(actor.role!=='admin')for(const r of result)store.patientAccess(actor,r.patient);
    return result;
  }
  admin();
  if(resource==='refunds'&&method==='POST'){
    fields(body,['paymentId','amountFils','reason','idempotencyKey']);requireThat(now()-actor.session.reauthed<=15*60000,403,'Confirm your password first.');requireThat(Number.isSafeInteger(body.amountFils)&&body.amountFils>0,400,'Enter a positive amount in fils.');const reason=text(body.reason,2000);
    return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{const p=store.get('SELECT * FROM payments WHERE id=?',text(body.paymentId,128));requireThat(p,404,'Payment unavailable.');const used=count("SELECT COALESCE(SUM(amount_fils),0) FROM payment_refunds WHERE payment=? AND status IN ('pending','settled')",p.id);requireThat(used+body.amountFils<=p.amount_fils,409,'Refund exceeds the unrefunded settled payment.');const refundId=id();store.run("INSERT INTO payment_refunds(id,payment,amount_fils,status,settled_at,recorded_by,reason) VALUES(?,?,?,'settled',?,?,?)",refundId,p.id,body.amountFils,now(),actor.id,reason);store.audit(actor.id,'desk.refund.recorded',refundId);return {id:refundId,status:'settled'};}));
  }
  if(resource==='rooms'&&method==='GET')return {rows:store.all('SELECT r.*,d.name AS department FROM rooms r LEFT JOIN departments d ON d.id=r.department_id ORDER BY display_label,r.id')};
  if(resource==='rooms'&&method==='POST'){
    fields(body,['id','label','departmentId','enabled','version']);const label=text(body.label,80);requireThat(typeof body.enabled==='boolean');
    if(body.departmentId!=null)requireThat(store.get('SELECT 1 FROM departments WHERE id=?',text(body.departmentId,128)),400,'Department unavailable.');
    const roomId=body.id??id();
    store.transaction(()=>{if(body.id==null)store.run('INSERT INTO rooms(id,display_label,department_id,enabled) VALUES(?,?,?,?)',roomId,label,body.departmentId??null,Number(body.enabled));
      else{requireThat(Number.isInteger(body.version));const old=store.get('SELECT * FROM rooms WHERE id=?',text(body.id,128));requireThat(old&&old.version===body.version,409,'Room changed. Reload before saving.');store.run('UPDATE rooms SET display_label=?,department_id=?,enabled=?,version=version+1 WHERE id=?',label,body.departmentId??null,Number(body.enabled),roomId);}
      store.audit(actor.id,'room.saved',roomId,{label,enabled:body.enabled});});return {ok:true};
  }
  const feedback=()=>store.all('SELECT f.*,u.name AS reporter_name,u.role AS reporter_role,h.name AS handler_name FROM feedback f LEFT JOIN users u ON u.id=f.reporter LEFT JOIN users h ON h.id=f.handler ORDER BY f.created DESC,f.id').map(safeFeedback);
  if(resource==='feedback'&&method==='GET')return {rows:feedback()};
  if(resource==='feedback'&&method==='POST'){
    fields(body,['id','status','version']);requireThat(['open','resolved'].includes(body.status));
    store.transaction(()=>{const f=store.get('SELECT * FROM feedback WHERE id=?',text(body.id,128));requireThat(f,404,'Feedback unavailable.');requireThat(f.version===body.version,409,'Feedback changed. Reload.');store.run('UPDATE feedback SET status=?,handler=?,handled=?,version=version+1 WHERE id=?',body.status,body.status==='resolved'?actor.id:null,body.status==='resolved'?now():null,f.id);store.audit(actor.id,'feedback.'+body.status,f.id);});return {ok:true};
  }
  if(resource==='users'&&method==='GET')return {rows:store.all('SELECT u.*,d.name AS department_name FROM users u LEFT JOIN departments d ON d.id=u.department ORDER BY u.name,u.id').map(u=>({...store.safeUser(u),nationalId:u.national_id,department:u.department,departmentName:u.department_name,job:u.job,version:u.auth_version})),assignments:store.all('SELECT patient,staff FROM care')};
  if(resource==='users'&&method==='POST'){
    fields(body,['accounts','active']);requireThat(typeof body.active==='boolean'&&Array.isArray(body.accounts)&&body.accounts.length>0&&body.accounts.length<=200);requireThat(now()-actor.session.reauthed<=15*60000,403,'Confirm your password first.');
    requireThat(new Set(body.accounts.map(a=>a.id)).size===body.accounts.length,400,'Duplicate account.');
    store.transaction(()=>{for(const input of body.accounts){const u=store.get('SELECT * FROM users WHERE id=?',text(input.id,128));requireThat(u,404,'Account unavailable.');requireThat(u.auth_version===input.version,409,'Account changed. Reload.');
      if(!body.active){requireThat(u.role!=='admin'||count("SELECT COUNT(*) FROM users WHERE role='admin' AND active=1")>1,409,'Cannot deactivate the last administrator.');
        requireThat(!store.get("SELECT 1 FROM appointments WHERE (patient=? OR staff=?) AND status IN ('booked','confirmed','checkedIn','inProgress')",u.id,u.id),409,'Resolve active bookings first.');
        requireThat(!store.get("SELECT 1 FROM tasks WHERE owner=? AND status NOT IN ('done','dismissed')",u.id),409,'Transfer clinical responsibilities first.');
        requireThat(u.role!=='staff'||!store.get('SELECT 1 FROM care WHERE staff=?',u.id),409,'Transfer care assignments first.');}
      store.run('UPDATE users SET active=?,auth_version=auth_version+1 WHERE id=?',Number(body.active),u.id);store.audit(actor.id,'account.active',u.id,{active:body.active});}});return {ok:true};
  }
  if(resource==='overview'&&method==='GET'){
    const day=url.searchParams.get('day')??clinicDay(now()),[start,end]=clinicBounds(day),days=Number(url.searchParams.get('days')??7),revenueDays=Number(url.searchParams.get('revenueDays')??7);
    requireThat(Number.isInteger(days)&&days>=1&&days<=31&&Number.isInteger(revenueDays)&&revenueDays>=1&&revenueDays<=31,400,'Invalid period.');
    const from=start-(days-1)*86400000;
    const appointments=store.all('SELECT a.*,p.name AS patient_name,p.gender,s.name AS staff_name,d.name AS department FROM appointments a JOIN users p ON p.id=a.patient JOIN users s ON s.id=a.staff LEFT JOIN departments d ON d.id=s.department WHERE a.start>=? AND a.start<? ORDER BY a.start,a.id',start,end).map(a=>({...a,slot_start:seconds(a.start),slot_end:seconds(a.end),patient_id:a.patient,staff_id:a.staff,reason_text:a.reason,room_number:a.room_label}));
    const period="a.start>=? AND a.start<? AND a.status NOT IN ('cancelled','noShow')";
    const gender=store.all(`SELECT u.gender,COUNT(*) AS n FROM appointments a JOIN users u ON u.id=a.patient WHERE ${period} GROUP BY u.gender`,from,end);
    const hours=store.all(`SELECT CAST(strftime('%H',(a.start+10800000)/1000,'unixepoch') AS INTEGER) AS hour,COUNT(*) AS n FROM appointments a WHERE ${period} GROUP BY hour ORDER BY hour`,from,end);
    const doctors=[];for(const d of store.all("SELECT * FROM users WHERE role='staff' AND job='doctor' AND active=1")){const slots=availableDoctorSlots(store,d.id,day,now());if(slots.length)doctors.push({id:d.id,name:d.name,specialty:d.specialty??'',next:seconds(Date.parse(slots[0].start))});}
    const revenue=[];for(let i=revenueDays-1;i>=0;i--){const dstart=start-i*86400000;revenue.push({day:clinicDay(dstart),payments:count('SELECT COALESCE(SUM(amount_fils),0) FROM payments WHERE at>=? AND at<?',dstart,dstart+86400000),refunds:count("SELECT COALESCE(SUM(amount_fils),0) FROM payment_refunds WHERE settled_at>=? AND settled_at<? AND status='settled'",dstart,dstart+86400000)});}
    return {day,days,stats:{patients:count("SELECT COUNT(*) FROM users WHERE role='patient'"),activePatients:count("SELECT COUNT(*) FROM users WHERE role='patient' AND active=1"),staff:count("SELECT COUNT(*) FROM users WHERE role='staff'"),activeStaff:count("SELECT COUNT(*) FROM users WHERE role='staff' AND active=1"),rooms:count('SELECT COUNT(*) FROM rooms WHERE enabled=1'),roomsConfigured:count('SELECT COUNT(*) FROM rooms')>0,consultations:count("SELECT COUNT(*) FROM appointments a WHERE status='completed' AND COALESCE(completed_at,(SELECT signed_at FROM signed_notes WHERE appointment=a.id))>=? AND COALESCE(completed_at,(SELECT signed_at FROM signed_notes WHERE appointment=a.id))<?",from,end),prescriptions:count('SELECT COUNT(*) FROM prescriptions WHERE issued_at>=? AND issued_at<?',from,end),referrals:count('SELECT COUNT(*) FROM referral_requests WHERE created>=? AND created<?',from,end)},appointments,gender,hours,doctors,revenue,feedback:feedback().slice(0,3),payments:store.all('SELECT p.*,u.name AS patient_name,i.description,i.id AS invoice_id,COALESCE((SELECT SUM(r.amount_fils)/1000.0 FROM payment_refunds r WHERE r.payment=p.id AND r.status=\'settled\'),0) AS refunded FROM payments p JOIN invoices i ON i.id=p.invoice JOIN users u ON u.id=i.patient ORDER BY p.at DESC,p.id LIMIT 8').map(p=>({...p,amount:p.amount_fils/1000,status:'settled',kind:'invoiceCharge',created_at:seconds(p.at),settled_at:seconds(p.at),request_reference:p.id})),limitations:['deskReceipts','unknownIssueDates','receiptsNotProfit']};
  }
  requireThat(false,404,'Workspace route unavailable.');
}
