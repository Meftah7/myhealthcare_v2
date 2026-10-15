(() => {
  const results=[];
  const check=(name,condition)=>{results.push({name,passed:!!condition});if(!condition)throw Error(name)};
  const clickText=(text)=>{const b=[...document.querySelectorAll('main button')].find(b=>b.textContent.trim()===text);if(!b)throw Error('Missing button '+text);b.click()};
  const change=(id,value)=>{const el=document.getElementById(id);el.value=value;el.dispatchEvent(new Event('change',{bubbles:true}))};
  const input=(id,value)=>{const el=document.getElementById(id);el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}))};
  const text=()=>document.querySelector('main').textContent;
  setRole('Doctor');
  check('Staff navigation has Chat and no primary Tasks',nav().some(n=>n[1]==='Chat')&&!nav().some(n=>n[1]==='Tasks'));
  check('Exactly three schedule tabs',document.querySelectorAll('main .tabs button').length===3);
  clickText('Upcoming');check('Overdue confirmed stays upcoming',text().includes('Late · Confirmed')&&text().includes('Omar Ali')&&!text().includes('No-show'));
  clickText('Completed');check('Completed state excludes cancelled/no-show',text().includes('08:30')&&![...document.querySelectorAll('main .card:first-child .badge')].some(e=>/Cancelled|No-show/.test(e.textContent)));
  go('patients');input('patient-search','diabetes');check('Authorized condition search',document.querySelectorAll('.patient').length===1&&text().includes('Amina Hasan'));
  input('patient-search','not-found');check('Patient empty search',text().includes('No matching completed-visit history'));
  patientQ='';change('patient-filter','Follow-up');check('Unique follow-up cards',document.querySelectorAll('.patient').length===2);
  setRole('Nurse');go('patients');check('Nurse participation gap explicit',text().includes('explicit encounter participation')&&document.querySelectorAll('.patient').length===0);
  setRole('Doctor');go('chat');input('message','QA preview message <safe>');document.querySelector('.composer').requestSubmit();check('Compose escapes message text',text().includes('QA preview message <safe>')&&threads[0].messages.at(-1).mine);
  change('chat-state','Loading');check('Chat loading state',text().includes('Loading sample'));
  clickText('Finish loading');change('chat-state','Error');clickText('Retry');check('Chat retry state',!!document.querySelector('.composer'));
  change('chat-state','Empty');check('Chat empty state',text().includes('No messages in this sample'));chatState='Ready';
  setRole('Admin');check('Admin required sections', ['Upcoming Appointments','Payment history','Appointments overview','Available doctors','Overall Appointments','Daily Revenue Report','Recent feedback'].every(s=>text().includes(s)));
  check('Two gender labels',document.querySelectorAll('.legend>div').length===2);
  changeDay(1);check('Clinic date navigation',day==='2026-10-16'&&text().includes('09:00'));
  changeDay(2);check('Clinic date empty state',text().includes('No upcoming appointments'));day=baseline;render();
  change('revenue-period','14 days');check('Revenue period recalculates',revenueDays===14&&text().includes('2026-10-02'));
  change('report-period','30 days');check('Appointment report period',reportDays===30);
  go('users');clickText('Staff');check('Role-aware filters',!!document.getElementById('staff-role')&&!document.getElementById('clinician'));
  change('staff-role','Nurse');check('Staff role filter',matchingUsers().length===1&&text().includes('Maryam Hasan'));
  clickText('Select accounts');clickText('Select visible');check('Select visible filtered accounts',selected.size===1);
  clickText('Review bulk action');check('Bulk review preserves protections',document.getElementById('dialog').open&&document.getElementById('dialog-content').textContent.includes('reauthentication'));document.getElementById('dialog').close();
  change('staff-role','Doctor');check('Filter change clears selections',selected.size===0);
  clickText('Admins');check('Category clears selections and irrelevant filters',selected.size===0&&!selection&&!document.getElementById('staff-role')&&!document.getElementById('clinician'));
  clickText('Patients');input('user-search','amina');check('Account identifier search',matchingUsers().length===1);clickText('Reset filters');check('Reset filters',matchingUsers().length===4);
  go('feedback');change('feedback-role','Admin');check('Feedback role filter',document.querySelectorAll('#feedback-results .row').length===1);
  clickText('Read & manage');document.querySelector('#dialog-content .primary').click();check('Feedback resolve attribution',feedback[1].status==='Resolved'&&feedback[1].handler.includes('Sample Admin'));
  clickText('Read & manage');document.querySelector('#dialog-content .primary').click();check('Feedback reopen',feedback[1].status==='Open');
  go('login');check('Seven demo roles, no login policy links',document.querySelectorAll('.demogrid button').length===7&&!text().includes('Terms')&&!text().includes('Privacy'));
  for(const r of ['Doctor','Nurse','Receptionist','Pharmacist','Dentist','Admin']){demoRole(r);check('Demo entry '+r,role===r&&page==='home')}
  go('login');demoRole('Patient');check('Patient shortcut preserves out-of-scope pages',document.getElementById('dialog').open);document.getElementById('dialog').close();
  go('home');const before=document.documentElement.dataset.theme;document.getElementById('theme').click();check('Theme switching',document.documentElement.dataset.theme!==before);document.getElementById('theme').click();
  go('analysis');check('Embedded detailed source analysis',text().includes('sharedModeBlocks')&&text().includes('schema version'));
  // Compile every authored inline handler on all main surfaces.
  for(const r of ['Doctor','Nurse','Dentist','Receptionist','Pharmacist','Admin']){
    setRole(r);for(const p of [...nav().map(n=>n[0]),'login','analysis']){go(p);for(const el of document.querySelectorAll('[onclick],[onchange],[oninput],[onsubmit]'))for(const a of ['onclick','onchange','oninput','onsubmit'])if(el.hasAttribute(a))new Function('event',el.getAttribute(a))}
  }
  setRole('Doctor');return JSON.stringify({passed:results.length,failed:0,checks:results});
})()
