import {digest,fields,id,requireThat,text} from './store.mjs';
import {clinicBounds} from './workspace_ops.mjs';

const clinical=['doctor','dentist','nurse'];
const known=[...clinical,'receptionist','pharmacist'];
const sec=value=>value==null?null:Math.floor(value/1000);
const dates=row=>Object.fromEntries(Object.entries(row).map(([k,v])=>[k,['slot_start','slot_end','assigned_at','recorded_at','requested_at','resolved_at','latest_at','sent_at'].includes(k)?sec(v):v]));

export function workforceOps({store,now,path,method,url,body,actor}) {
  if(!path.startsWith('/api/workforce/'))return undefined;
  const resource=path.slice('/api/workforce/'.length), count=(sql,...args)=>Number(Object.values(store.get(sql,...args))[0]);
  requireThat(actor.role==='staff'&&known.includes(actor.job)||actor.role==='patient'&&resource==='vitals',403,'A validated staff profile is required.');
  const member=conversation=>requireThat(store.get('SELECT 1 FROM staff_conversation_members WHERE conversation=? AND user=?',conversation,actor.id),403,'Conversation membership required.');
  const intakes=()=>{
    requireThat(clinical.includes(actor.job),403,'Nursing care access required.');
    return store.all(`SELECT ni.id,ni.appointment AS appointment_id,ni.nurse AS nurse_id,ni.status,ni.note AS observation_note,ni.version,ni.assigned_at,ni.recorded_at,
      a.patient AS patient_id,a.start AS slot_start,a.end AS slot_end,a.status AS appointment_status,owner.department AS department_id,
      u.name AS patient_name,u.national_id,d.name AS department,v.temp_c,v.heart_rate,v.spo2,
      EXISTS(SELECT 1 FROM tasks t WHERE t.patient=a.patient AND t.kind='resultReview' AND t.priority='urgent' AND t.status NOT IN ('done','dismissed')) AS urgent
      FROM nursing_intakes ni JOIN appointments a ON a.id=ni.appointment JOIN users u ON u.id=a.patient JOIN users owner ON owner.id=a.staff
      LEFT JOIN departments d ON d.id=owner.department LEFT JOIN vitals v ON v.id=ni.vitals
      WHERE ${actor.job==='nurse'?'ni.nurse':'a.staff'}=? AND a.status NOT IN ('cancelled','noShow') ORDER BY a.start,ni.id`,actor.id)
      .filter(row=>{try{store.patientAccess(actor,row.patient_id);return true;}catch(error){if(error.status===403)return false;throw error;}}).map(dates);
  };
  if(method==='GET'){
    if(resource==='activity')return {rows:store.all('SELECT action,entity,at FROM audit WHERE actor=? ORDER BY seq DESC LIMIT 100',actor.id).map(row=>({...row,at:sec(row.at)}))};
    if(resource==='directory')return {rows:store.all(`SELECT u.id,u.name,u.job AS role,d.name AS department,
      COALESCE((SELECT MIN(start_min) FROM staff_shifts WHERE staff=u.id),(SELECT MIN(start_min) FROM schedules WHERE staff=u.id)) AS start_minutes,
      COALESCE((SELECT MAX(end_min) FROM staff_shifts WHERE staff=u.id),(SELECT MAX(end_min) FROM schedules WHERE staff=u.id)) AS end_minutes
      FROM users u LEFT JOIN departments d ON d.id=u.department WHERE u.role='staff' AND u.active=1 ORDER BY u.name,u.id`)};
    if(resource==='shifts')return {rows:store.all('SELECT id,weekday,start_min AS start_minutes,end_min AS end_minutes FROM staff_shifts WHERE staff=? ORDER BY weekday,start_min',actor.id)};
    if(resource==='vitals'){
      const patient=text(url.searchParams.get('patientId'),128);store.patientAccess(actor,patient);
      const from=url.searchParams.get('from'),to=url.searchParams.get('to');
      return {rows:store.all('SELECT * FROM vitals WHERE patient=? AND recorded_at>=? AND recorded_at<=? ORDER BY recorded_at DESC,id',patient,from?Date.parse(from):0,to?Date.parse(to):8640000000000000)};
    }
    if(resource==='intakes')return {rows:intakes()};
    if(resource==='document-desk'){
      requireThat(actor.job==='receptionist',403,'Front desk access required.');
      const reference=text(url.searchParams.get('reference'),200),document=store.get("SELECT * FROM documents WHERE reference_hash=? OR json_extract(snapshot,'$.verificationReference')=? COLLATE NOCASE",digest(reference),reference);
      requireThat(document,404,'No issued document matches this reference.');
      store.audit(actor.id,'document.deskLookup',document.id);
      return {...document,snapshot:undefined,file_id:undefined,sha256:undefined,reference_hash:undefined,reference};
    }
    if(resource==='conversations')return {rows:store.all(`SELECT c.id,u.id AS peer_id,u.name AS peer_name,u.job AS peer_role,
      (SELECT body FROM staff_messages WHERE conversation=c.id ORDER BY sent_at DESC,id DESC LIMIT 1) AS latest_message,
      (SELECT MAX(sent_at) FROM staff_messages WHERE conversation=c.id) AS latest_at,
      (SELECT COUNT(*) FROM staff_messages m WHERE m.conversation=c.id AND m.sender!=? AND m.sent_at>COALESCE(mine.last_read_at,0)) AS unread
      FROM staff_conversations c JOIN staff_conversation_members mine ON mine.conversation=c.id AND mine.user=?
      JOIN staff_conversation_members peer ON peer.conversation=c.id AND peer.user!=? JOIN users u ON u.id=peer.user
      ORDER BY latest_at DESC,c.id`,actor.id,actor.id,actor.id).map(dates)};
    if(resource==='thread'){
      const conversation=text(url.searchParams.get('id'),128);member(conversation);
      return {rows:store.all('SELECT m.id,m.conversation AS conversation_id,m.sender AS sender_id,m.body,m.sent_at,u.name AS sender_name FROM staff_messages m JOIN users u ON u.id=m.sender WHERE conversation=? ORDER BY sent_at,m.id',conversation).map(dates)};
    }
    if(resource==='clarifications'){
      requireThat(['doctor','dentist','pharmacist'].includes(actor.job),403,'Medication review access required.');
      return {rows:store.all(`SELECT c.id,c.prescription AS medication_id,c.question,c.requested_at,c.version,p.name AS medication_name,p.dose,p.patient AS patient_id,u.name AS patient_name
        FROM medication_clarifications c JOIN prescriptions p ON p.id=c.prescription JOIN users u ON u.id=p.patient
        WHERE c.resolved_at IS NULL ${actor.job==='pharmacist'?'':'AND p.prescriber=?'} ORDER BY c.requested_at`,...(actor.job==='pharmacist'?[]:[actor.id])).map(dates)};
    }
    if(resource==='dispensing-history'){
      requireThat(actor.job==='pharmacist',403,'Pharmacy access required.');
      return {rows:store.all('SELECT x.id,x.prescription AS medication_id,x.outcome,x.quantity,x.at AS recorded_at,x.note,p.name AS medication_name,u.name AS patient_name,ph.name AS pharmacist_name FROM dispenses x JOIN prescriptions p ON p.id=x.prescription JOIN users u ON u.id=x.patient JOIN users ph ON ph.id=x.pharmacist ORDER BY x.at DESC,x.id LIMIT 100').map(dates)};
    }
    if(resource==='home'){
      const day=new Date(now()+10800000).toISOString().slice(0,10),[start,end]=clinicBounds(day),stats={}, queue=[];
      if(actor.job==='nurse'){
        const assigned=intakes();queue.push(...assigned);
        stats.assignedToday=new Set(assigned.filter(n=>n.slot_start>=start/1000&&n.slot_start<end/1000).map(n=>n.patient_id)).size;
        stats.completedToday=assigned.filter(n=>n.status==='completed'&&n.recorded_at>=start/1000&&n.recorded_at<end/1000).length;
        stats.observationsDue=assigned.filter(n=>n.status==='pending').length;
        stats.handover=count("SELECT COUNT(*) FROM tasks WHERE owner=? AND status NOT IN ('done','dismissed')",actor.id);
      }else if(actor.job==='pharmacist'){
        stats.pendingOrders=count("SELECT COUNT(*) FROM prescriptions p JOIN signed_notes s ON s.appointment=p.appointment WHERE p.active=1 AND NOT EXISTS(SELECT 1 FROM dispenses x WHERE x.prescription=p.id AND x.outcome='dispensed')");
        stats.dispensedToday=count("SELECT COUNT(DISTINCT prescription) FROM dispenses WHERE outcome='dispensed' AND at>=? AND at<?",start,end);
        stats.clarifications=count('SELECT COUNT(*) FROM medication_clarifications WHERE resolved_at IS NULL');
        stats.stockAlerts=count('SELECT COUNT(*) FROM stock WHERE quantity<=5 OR expiry<=?',end+30*86400000);
        queue.push(...store.all("SELECT p.id,p.name AS medication_name,p.patient AS patient_id,u.name AS patient_name,p.dose,p.frequency FROM prescriptions p JOIN signed_notes s ON s.appointment=p.appointment JOIN users u ON u.id=p.patient WHERE p.active=1 AND NOT EXISTS(SELECT 1 FROM dispenses x WHERE x.prescription=p.id AND x.outcome='dispensed') ORDER BY p.issued_at,p.id LIMIT 100"));
      }else{
        const desk=actor.job==='receptionist',scope=desk?'1':'a.staff=?',args=desk?[]:[actor.id];
        stats.appointmentsToday=count(`SELECT COUNT(*) FROM appointments a WHERE ${scope} AND a.start>=? AND a.start<?`,...args,start,end);
        if(desk){
          stats.checkedIn=count('SELECT COUNT(*) FROM appointments WHERE checked_in IS NOT NULL AND start>=? AND start<?',start,end);
          stats.waiting=count("SELECT COUNT(*) FROM appointments WHERE status IN ('booked','confirmed') AND checked_in IS NULL AND start>=? AND start<?",start,end);
          stats.pendingCopies=count("SELECT COUNT(*) FROM documents d WHERE d.validity='valid' AND NOT EXISTS(SELECT 1 FROM document_copy_confirmations c WHERE c.document=d.id AND c.document_version=d.version)");
        }else{
          stats.completedToday=count("SELECT COUNT(*) FROM appointments a WHERE a.staff=? AND a.status='completed' AND COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment=a.id))>=? AND COALESCE(a.completed_at,(SELECT signed_at FROM signed_notes WHERE appointment=a.id))<?",actor.id,start,end);
          stats.followUp=count("SELECT COUNT(*) FROM tasks WHERE owner=? AND kind='followUpDue' AND status NOT IN ('done','dismissed')",actor.id);
          stats.unsignedNotes=count('SELECT COUNT(*) FROM encounter_drafts e WHERE e.author=? AND NOT EXISTS(SELECT 1 FROM signed_notes s WHERE s.appointment=e.appointment)',actor.id);
        }
        queue.push(...store.all(`SELECT a.id,a.patient AS patient_id,a.staff AS staff_id,a.start AS slot_start,a.end AS slot_end,a.status,a.visit_type,a.reason AS reason_text,a.room_label AS room_number,u.name AS patient_name FROM appointments a JOIN users u ON u.id=a.patient WHERE ${scope} AND a.status IN ('booked','confirmed','checkedIn','inProgress') AND a.end>=? ORDER BY CASE WHEN a.status='inProgress' THEN 0 ELSE 1 END,a.start,a.id LIMIT 100`,...args,start).map(dates));
      }
      return {role:actor.job,name:actor.name,department:store.get('SELECT name FROM departments WHERE id=?',actor.department??'')?.name??null,stats,queue};
    }
  }
  if(resource==='document-copy'&&method==='POST'){
    requireThat(actor.job==='receptionist',403,'Front desk access required.');fields(body,['id','recipientIdentityChecked','reason','idempotencyKey']);
    requireThat(body.recipientIdentityChecked===true,400,'Verify recipient identity first.');const reason=text(body.reason,1000);
    return store.transaction(()=>{
      const document=store.get('SELECT * FROM documents WHERE id=?',text(body.id,128));requireThat(document&&document.validity==='valid'&&document.render==='ready',409,'Only a current, rendered issued copy can be confirmed.');
      requireThat(digest(store.readFile(document.file_id))===document.sha256,409,'Stored document fingerprint does not match.');
      return store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
        const at=now();store.run('INSERT INTO document_copy_confirmations(id,document,document_version,operator,at,reason,request_key) VALUES(?,?,?,?,?,?,?)',id(),document.id,document.version,actor.id,at,reason,body.idempotencyKey);store.audit(actor.id,'document.copyConfirmed',document.id);return {at};
      });
    });
  }
  if(resource==='vitals'&&method==='POST'){
    fields(body,['id','patientId','appointmentId','temperature','pulse','oxygen','systolic','diastolic','weightKg','heightCm','glucose']);
    requireThat(clinical.includes(actor.job)||actor.role==='patient',403,'Clinical care access required.');const patient=text(body.patientId,128);store.patientAccess(actor,patient);
    requireThat(actor.role!=='patient'||!body.appointmentId,403,'Home readings cannot name a clinic encounter.');
    const appointment=body.appointmentId?store.get('SELECT * FROM appointments WHERE id=?',text(body.appointmentId,128)):null;
    requireThat(!body.appointmentId||appointment?.patient===patient,400,'Encounter and patient must match.');
    for(const name of ['temperature','weightKg','heightCm','glucose'])requireThat(body[name]==null||typeof body[name]==='number'&&Number.isFinite(body[name]),400,'Check numeric observations.');
    for(const name of ['pulse','systolic','diastolic'])requireThat(body[name]==null||Number.isInteger(body[name])&&body[name]>0,400,'Check whole-number observations.');
    requireThat(body.oxygen==null||Number.isInteger(body.oxygen)&&body.oxygen>=0&&body.oxygen<=100,400,'Oxygen saturation must be 0–100%.');
    return store.transaction(()=>store.retry(actor.id,text(body.id,128),{path,body},()=>{
      const at=now(),recordedByStaffId=actor.role==='staff'?actor.id:null;
      store.run('INSERT INTO vitals(id,patient,appointment,recorded_by,recorded_at,temp_c,heart_rate,spo2,systolic,diastolic,weight_kg,height_cm,glucose) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',body.id,patient,appointment?.id??null,recordedByStaffId,at,body.temperature??null,body.pulse??null,body.oxygen??null,body.systolic??null,body.diastolic??null,body.weightKg??null,body.heightCm??null,body.glucose??null);
      store.audit(actor.id,'vitals.added',body.id);return {id:body.id,recordedAt:at,recordedByStaffId};
    }));
  }
  if(resource==='conversations'&&method==='POST'){
    fields(body,['peerId']);const peer=text(body.peerId,128), recipient=store.get("SELECT * FROM users WHERE id=? AND role='staff' AND active=1",peer);
    requireThat(peer!==actor.id&&recipient&&known.includes(recipient.job),403,'Choose another active staff recipient.');
    return store.transaction(()=>{
      const pair=[actor.id,peer].sort().join('|'),prior=store.get('SELECT id FROM staff_conversations WHERE pair_key=?',pair);if(prior)return prior;
      const conversation=id();store.run('INSERT INTO staff_conversations(id,pair_key,created_by,created_at) VALUES(?,?,?,?)',conversation,pair,actor.id,now());
      for(const user of [actor.id,peer])store.run('INSERT INTO staff_conversation_members(conversation,user) VALUES(?,?)',conversation,user);
      store.audit(actor.id,'staff.conversation.created',conversation);return {id:conversation};
    });
  }
  if(resource==='messages'&&method==='POST'){
    fields(body,['conversationId','body','idempotencyKey']);const conversation=text(body.conversationId,128);member(conversation);
    requireThat(count('SELECT COUNT(*) FROM staff_conversation_members m JOIN users u ON u.id=m.user WHERE m.conversation=? AND u.active=1',conversation)===2,403,'Both participants must be active to send.');
    const message=text(body.body,4000);
    return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
      const messageId=id();store.run('INSERT INTO staff_messages(id,conversation,sender,body,request_key,sent_at) VALUES(?,?,?,?,?,?)',messageId,conversation,actor.id,message,text(body.idempotencyKey,128),now());
      store.audit(actor.id,'staff.message.sent',conversation);return {id:messageId};
    }));
  }
  if(resource==='read'&&method==='POST'){
    fields(body,['conversationId']);const conversation=text(body.conversationId,128);member(conversation);
    store.run('UPDATE staff_conversation_members SET last_read_at=MAX(COALESCE(last_read_at,0),?) WHERE conversation=? AND user=?',now(),conversation,actor.id);return {ok:true};
  }
  if(resource==='intake-assignments'&&method==='POST'){
    fields(body,['appointmentId','nurseId']);const a=store.get('SELECT * FROM appointments WHERE id=?',text(body.appointmentId,128)),n=store.get("SELECT * FROM users WHERE id=? AND role='staff' AND job='nurse' AND active=1",text(body.nurseId,128));
    requireThat(a&&n,404,'Visit or nurse unavailable.');requireThat(actor.job==='receptionist'||['doctor','dentist'].includes(actor.job)&&a.staff===actor.id,403,'Only the responsible clinician or authorized desk can assign intake.');
    requireThat(!['completed','cancelled','noShow'].includes(a.status),409,'Assign intake to an active visit.');
    return store.transaction(()=>{
      const key='intake_'+a.id+'_'+n.id;store.run('INSERT OR IGNORE INTO nursing_intakes(id,appointment,nurse,assigned_at) VALUES(?,?,?,?)',key,a.id,n.id,now());
      store.run('INSERT OR IGNORE INTO care(patient,staff) VALUES(?,?)',a.patient,n.id);store.audit(actor.id,'nursing.intake.assigned',key);return {id:key};
    });
  }
  if(resource==='intakes'&&method==='POST'){
    fields(body,['id','version','note','temperature','pulse','oxygen','idempotencyKey']);requireThat(actor.job==='nurse',403,'Nurse access required.');
    const note=body.note??'';requireThat(typeof note==='string'&&note.length<=5000,400,'Use a nursing note of at most 5000 characters.');
    requireThat(note.trim()||[body.temperature,body.pulse,body.oxygen].some(v=>v!=null),400,'Record an observation or nursing note.');
    requireThat(body.temperature==null||typeof body.temperature==='number'&&Number.isFinite(body.temperature),400,'Check temperature in Celsius.');
    requireThat(body.pulse==null||Number.isInteger(body.pulse)&&body.pulse>0,400,'Check pulse in beats/min.');
    requireThat(body.oxygen==null||Number.isInteger(body.oxygen)&&body.oxygen>=0&&body.oxygen<=100,400,'Oxygen saturation must be 0–100%.');
    const intake=store.get('SELECT ni.*,a.patient,a.status AS appointment_status FROM nursing_intakes ni JOIN appointments a ON a.id=ni.appointment WHERE ni.id=? AND ni.nurse=?',text(body.id,200),actor.id);
    requireThat(intake,403,'This intake is not assigned to you.');store.patientAccess(actor,intake.patient);requireThat(!['cancelled','noShow'].includes(intake.appointment_status),409,'This visit is no longer active.');
    return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
      const current=store.get('SELECT * FROM nursing_intakes WHERE id=?',intake.id);requireThat(current.version===body.version,409,'Intake changed. Reload before saving; your input is retained.');
      const vital=id(),at=now();store.run('INSERT INTO vitals(id,patient,appointment,recorded_by,recorded_at,temp_c,heart_rate,spo2) VALUES(?,?,?,?,?,?,?,?)',vital,intake.patient,intake.appointment,actor.id,at,body.temperature??null,body.pulse??null,body.oxygen??null);
      store.run("UPDATE nursing_intakes SET status='completed',note=?,vitals=?,recorded_at=?,recorded_by=?,last_request_key=?,version=version+1 WHERE id=?",note.trim(),vital,at,actor.id,body.idempotencyKey,intake.id);
      store.run('INSERT OR IGNORE INTO encounter_participants(appointment,staff,participated_at,recorded_by) VALUES(?,?,?,?)',intake.appointment,actor.id,at,actor.id);
      store.audit(actor.id,'nursing.intake.saved',intake.id);return {id:intake.id,vitalsId:vital};
    }));
  }
  if(resource==='clarifications'&&method==='POST'){
    fields(body,['id','version','resolution','idempotencyKey']);requireThat(['doctor','dentist'].includes(actor.job)&&actor.credential_until>now(),403,'A current prescriber credential is required.');
    const item=store.get('SELECT c.*,p.prescriber,p.patient FROM medication_clarifications c JOIN prescriptions p ON p.id=c.prescription WHERE c.id=?',text(body.id,128));
    requireThat(item&&item.prescriber===actor.id,403,'Only the responsible prescriber can resolve this clarification.');store.patientAccess(actor,item.patient);
    const resolution=text(body.resolution,4000);
    return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
      const changed=store.run('UPDATE medication_clarifications SET resolution=?,resolved_by=?,resolved_at=?,version=version+1 WHERE id=? AND version=? AND resolved_at IS NULL',resolution,actor.id,now(),item.id,body.version);
      requireThat(changed.changes===1,409,'Clarification changed. Reload and retry.');store.audit(actor.id,'pharmacy.clarification.resolved',item.id);return {ok:true};
    }));
  }
  return undefined;
}
