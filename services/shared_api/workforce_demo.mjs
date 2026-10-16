import {demoRoster} from './workforce_manifest.mjs';
import {availableDoctorSlots} from './workspace_ops.mjs';
import {requireThat} from './store.mjs';

export function sharedDemoManifest(store) {
  requireThat(store.get("SELECT value FROM settings WHERE key='synthetic'")?.value==='true',403,'Not a synthetic database.');
  return store.all("SELECT u.id,u.name,u.email,u.role AS accountType,u.job AS professionalRole,d.name AS department,u.active AS active FROM users u LEFT JOIN departments d ON d.id=u.department WHERE u.role IN ('staff','admin') ORDER BY u.role,u.job,u.email");
}

/** Explicit offline demo initialization/repair. Existing passwords/status win. */
export function provisionSharedDemo(store,{password,initialize=false,now=Date.now}={}) {
  const empty=store.get('SELECT COUNT(*) n FROM users').n===0;
  requireThat(initialize ? empty : store.get("SELECT value FROM settings WHERE key='synthetic'")?.value==='true',403,'Explicit synthetic initialization or a previously marked synthetic database is required.');
  requireThat(typeof password==='string'&&password.length>=12,400,'Configure MYHEALTH_DEMO_PASSWORD (at least 12 characters) for newly created shared demo accounts.');
  return store.transaction(()=>{
    if(initialize)store.run("INSERT INTO settings(key,value) VALUES('synthetic','true')");
    const issues=[], roster=demoRoster(), staff=[];
    for(const row of roster){
      const accountType=row.role==='admin'?'admin':'staff';
      let user=store.get('SELECT * FROM users WHERE email=?',row.sharedEmail);
      if(!user){
        const stable='demo_'+row.id;
        if(store.get('SELECT 1 FROM users WHERE id=?',stable)){issues.push(row.sharedEmail+': stable identifier collision');continue;}
        store.addUser({userId:stable,email:row.sharedEmail,name:row.name,role:accountType,job:accountType==='staff'?row.role:null,password,
          credentialUntil:['doctor','dentist','nurse','pharmacist'].includes(row.role)?now()+365*86400000:null});
        user=store.get('SELECT * FROM users WHERE id=?',stable);
      }
      if(user.role!==accountType||accountType==='staff'&&user.job!==row.role){issues.push(row.sharedEmail+': administrator role repair required');continue;}
      if(accountType==='admin')continue;
      let department=store.get('SELECT * FROM departments WHERE id=? OR name=?',row.departmentId,row.departmentName);
      if(!department){store.run('INSERT INTO departments(id,name) VALUES(?,?)',row.departmentId,row.departmentName);department={id:row.departmentId};}
      if(!user.department)store.run('UPDATE users SET department=? WHERE id=?',department.id,user.id);
      if(!user.active){issues.push(row.sharedEmail+': inactive; administrator recovery required');continue;}
      const marker='demo.roster.schedule:'+user.id;
      if(!store.get('SELECT 1 FROM settings WHERE key=?',marker)){
        if(['doctor','dentist'].includes(user.job)){
          if(!store.get('SELECT 1 FROM schedules WHERE staff=?',user.id))for(const weekday of [7,1,2,3,4])store.run('INSERT INTO schedules(staff,weekday,start_min,end_min) VALUES(?,?,480,960)',user.id,weekday);
        }else if(!store.get('SELECT 1 FROM staff_shifts WHERE staff=?',user.id)){
          for(const weekday of [7,1,2,3,4])store.run('INSERT INTO staff_shifts(id,staff,weekday,start_min,end_min,department) VALUES(?,?,?,480,960,?)','demo_shift_'+user.id+'_'+weekday,user.id,weekday,department.id);
        }
        store.run("INSERT INTO settings(key,value) VALUES(?,'complete')",marker);
      }
      staff.push(store.get('SELECT * FROM users WHERE id=?',user.id));
    }
    const patients=[];
    for(let n=1;n<=24;n++){
      const email=(n===1?'patient':'patient'+n)+'@shared.demo';
      let patient=store.get('SELECT * FROM users WHERE email=?',email);
      if(!patient){
        const patientId='demo_patient_'+String(n).padStart(3,'0');
        requireThat(!store.get('SELECT 1 FROM users WHERE id=?',patientId),409,'Synthetic patient identifier collision.');
        store.addUser({userId:patientId,email,name:'Synthetic Patient '+String(n).padStart(2,'0'),role:'patient',password});
        store.run('UPDATE users SET gender=? WHERE id=?',n%2?'female':'male',patientId);
        patient=store.get('SELECT * FROM users WHERE id=?',patientId);
      }
      if(patient.role==='patient'&&patient.active)patients.push(patient);
    }
    const clinicians=staff.filter(u=>['doctor','dentist'].includes(u.job));
    const day=new Date(now()+10800000).toISOString().slice(0,10);
    const visit=(key,clinician,patient,arrived=false)=>{
      const prior=store.get('SELECT * FROM appointments WHERE id=?',key);if(prior)return prior;
      for(let offset=0;offset<7;offset++){
        const date=new Date(Date.parse(day+'T00:00Z')+offset*86400000).toISOString().slice(0,10);
        const slot=availableDoctorSlots(store,clinician.id,date,now()+300000)[0];if(!slot)continue;
        store.run('INSERT INTO appointments(id,patient,staff,start,end,status,reason,booked_by,booked_at) VALUES(?,?,?,?,?,?,?,?,?)',key,patient.id,clinician.id,Date.parse(slot.start),Date.parse(slot.end),arrived?'checkedIn':'booked','Synthetic demonstration visit',clinician.id,now());
        store.run('INSERT OR IGNORE INTO care(patient,staff) VALUES(?,?)',patient.id,clinician.id);
        return store.get('SELECT * FROM appointments WHERE id=?',key);
      }
      return null;
    };
    if(patients.length){
      clinicians.forEach((c,i)=>visit('demo_roster_visit_'+c.id,c,patients[i%patients.length]));
      staff.filter(u=>u.job==='nurse').forEach((n,i)=>{
        const options=clinicians.filter(c=>c.department===n.department);if(!options.length)return;
        const a=visit('demo_roster_intake_'+n.id,options[i%options.length],patients[(i+12)%patients.length],true);if(!a)return;
        store.run('INSERT OR IGNORE INTO care(patient,staff) VALUES(?,?)',a.patient,n.id);
        store.run('INSERT OR IGNORE INTO nursing_intakes(id,appointment,nurse,assigned_at) VALUES(?,?,?,?)','demo_intake_'+n.id,a.id,n.id,now());
      });
      const doctor=clinicians.find(c=>c.job==='doctor'),pharmacist=staff.find(u=>u.job==='pharmacist');
      if(doctor&&pharmacist&&!store.get("SELECT 1 FROM prescriptions WHERE id='demo_roster_prescription'")){
        const at=now()-86400000,p=patients[0],appointment='demo_roster_signed_visit';
        store.run("INSERT OR IGNORE INTO appointments(id,patient,staff,start,end,status,reason,booked_by,booked_at,completed_at) VALUES(?,?,?,?,?,'completed',?,?,?,?)",appointment,p.id,doctor.id,at-1200000,at,'Completed synthetic medication review',doctor.id,at-86400000,at);
        store.run('INSERT OR IGNORE INTO signed_notes(appointment,patient,signer,note,signed_at) VALUES(?,?,?,?,?)',appointment,p.id,doctor.id,'Synthetic demonstration consultation; confirm the signed instructions before supply.',at);
        store.run('INSERT INTO prescriptions(id,patient,prescriber,appointment,name,dose,frequency,start,issued_at) VALUES(?,?,?,?,?,?,?,?,?)','demo_roster_prescription',p.id,doctor.id,appointment,'Paracetamol','500 mg','As written in the signed demonstration order',at,at);
        store.run('INSERT OR IGNORE INTO care(patient,staff) VALUES(?,?)',p.id,doctor.id);
        store.run("INSERT OR IGNORE INTO stock(id,item,batch,expiry,quantity,unit,received_by,received_at) VALUES('demo_roster_stock','Paracetamol','SYNTHETIC-001',?,100,'tablets',?,?)",now()+365*86400000,pharmacist.id,now());
      }
    }
    store.run("INSERT OR IGNORE INTO settings(key,value) VALUES('clinicName','Synthetic Shared Demo Clinic')");
    store.audit(null,'synthetic.roster.repaired','demo-workforce');
    return {accounts:sharedDemoManifest(store),issues};
  });
}
