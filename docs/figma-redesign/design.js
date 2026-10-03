/* Shared, editable design specification for the preview and Figma builder. */
(function (root) {
  'use strict';
  const colors = {
    page:'#F3F6FB', surface:'#FFFFFF', primary:'#1E5FAF', primaryDark:'#174C8E',
    header:'#E3ECF8', ink:'#152C49', muted:'#586A81', border:'#DFE7F1',
    blueTint:'#EEF4FC', blueText:'#1E5FAF', greenTint:'#E4F3EA', greenText:'#216746',
    amberTint:'#FFF2DD', amberText:'#8A5109', redTint:'#FCE8E7', redText:'#A13432',
    white:'#FFFFFF', whiteMuted:'#DFEAF9', transparent:null,
  };
  const icons = {
    home:'M3 10 12 3l9 7v10h-6v-7H9v7H3Z',
    calendar:'M4 5h16v16H4ZM8 3v4m8-4v4M4 10h16',
    record:'M6 3h8l4 4v14H6ZM14 3v5h5M9 12h6m-6 4h6',
    user:'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM4 21v-2a8 8 0 0 1 16 0v2',
    users:'M9 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM2 21v-2a7 7 0 0 1 14 0v2M16 4a4 4 0 0 1 0 8m2 3a6 6 0 0 1 4 6',
    heart:'M20.8 4.6a5.4 5.4 0 0 0-7.6 0L12 5.8l-1.2-1.2a5.4 5.4 0 0 0-7.6 7.6L12 21l8.8-8.8a5.4 5.4 0 0 0 0-7.6ZM4 12h4l2-4 3 8 2-4h5',
    bell:'M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9ZM10 21h4',
    settings:'M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8ZM12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10 2 2M5 19l2-2M17 7l2-2',
    search:'M10 3a7 7 0 1 0 0 14 7 7 0 0 0 0-14ZM15 15l6 6',
    chevron:'m9 5 7 7-7 7', back:'m15 5-7 7 7 7', plus:'M12 5v14M5 12h14',
    check:'m5 12 4 4L19 6', clock:'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20ZM12 6v6l4 2',
    chat:'M4 3h16v14H9l-5 4ZM8 8h8m-8 4h5',
    pill:'M5 19a5 5 0 0 1 0-7l7-7a5 5 0 0 1 7 7l-7 7a5 5 0 0 1-7 0ZM8 9l7 7',
    lab:'M9 3h6M10 3v7l-6 9a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2l-6-9V3M7 15h10',
    wallet:'M3 6h17v15H3ZM3 6V3h14v3M15 12h6v5h-6Z',
    chart:'M4 3v18h17M8 16v-4m5 4V8m5 8V5',
    building:'M5 21V3h14v18M2 21h20M9 7h1m4 0h1M9 11h1m4 0h1M10 21v-5h4v5',
    tasks:'M4 4h16v17H4ZM8 3h8v4H8ZM8 12l1 1 2-2m3 1h3M8 17h9',
    nutrition:'M6 3v7m-3-7v5a3 3 0 0 0 6 0V3M6 11v10M18 3c-3 4-3 8 0 9h2V3ZM20 12v9',
    lock:'M5 10h14v11H5ZM8 10V6a4 4 0 0 1 8 0v4M12 14v3',
    mail:'M3 5h18v14H3Zm0 0 9 7 9-7', download:'M12 3v12m-5-5 5 5 5-5M4 17v4h16v-4',
    warning:'M12 3 2 21h20ZM12 9v5m0 3v1', logout:'M10 4H4v16h6m4-13 5 5-5 5M8 12h12',
  };
  const F = (name, children=[], style={}) => ({kind:'frame', name, children, style});
  const T = (value, size=14, weight=400, color='ink', style={}) => ({kind:'text', name:value, text:value, style:{size,weight,color,...style}});
  const I = (icon, color='primary', size=20) => ({kind:'icon',name:icon,icon,style:{color,width:size,height:size}});
  const row = (children, style={}) => F('Row',children,{direction:'row',gap:12,align:'center',...style});
  const col = (children, style={}) => F('Column',children,{direction:'column',gap:8,...style});
  const button = (label,target,variant='primary') => ({kind:'button',name:label,text:label,target,style:{variant,height:48}});
  const badge = (label,tone='green') => ({kind:'badge',name:label,text:label,style:{tone}});
  const field = (label,value,icon='user',extra) => col([T(label,12,600,'ink'),row([I(icon,'muted',18),T(value,14,400,'muted',{grow:1}),...(extra?[T(extra,12,600,'primary')]:[])],{padding:14,bg:'surface',border:'border',radius:12,minHeight:48})],{gap:8});
  const note = (label,icon='warning',tone='amber') => row([I(icon,tone+'Text',18),T(label,12,500,tone+'Text',{grow:1})],{bg:tone+'Tint',padding:12,radius:12,gap:10});
  const card = (children,style={}) => col(children,{padding:16,bg:'surface',border:'border',radius:16,gap:12,...style});
  const h = (label,action,target) => row([T(label,16,600,'ink',{grow:1}),...(action?[T(action,12,600,'primary',{target})]:[])],{gap:8});
  const divider = () => F('Divider',[],{height:1,bg:'border'});
  const listrow = (icon,title,subtitle,status,tone='green',target) => ({...row([
    F('Icon', [I(icon)],{width:40,height:40,bg:'blueTint',radius:12,align:'center',justify:'center'}),
    col([T(title,14,600),...(subtitle?[T(subtitle,12,400,'muted')]:[])],{grow:1,gap:4}),
    ...(status?[badge(status,tone)]:[I('chevron','muted',16)]),
  ],{padding:14,bg:'surface',border:'border',radius:14,gap:12}),target});
  const menu = (items) => card(items.flatMap((it,i)=>[...(i?[divider()]:[]),{...row([I(it[0],it[3]?'redText':'primary',18),T(it[1],14,500,it[3]?'redText':'ink',{grow:1}),I('chevron','muted',16)],{minHeight:42,gap:12}),target:it[2]}]),{gap:6});
  const chips = (labels,selected=0) => row(labels.map((label,i)=>({kind:'chip',name:label,text:label,style:{selected:i===selected}})),{gap:8});
  const metrics = (entries) => row(entries.map(e=>card([T(e[0],11,500,'muted'),T(e[1],20,600),...(e[2]?[T(e[2],11,400,'muted')]:[])],{grow:1,padding:12,gap:6})),{gap:10});
  const progress = (current,total=3) => row(Array.from({length:total},(_,i)=>F('Step '+(i+1),[],{height:4,grow:1,bg:i<current?'primary':'border',radius:2})),{gap:6});
  const search = (text='Search') => row([I('search','muted',18),T(text,13,400,'muted',{grow:1})],{padding:14,bg:'surface',border:'border',radius:12});
  const identity = (name,sub,role,photoTarget) => card([row([F('Avatar',[I('user','primary',24)],{width:52,height:52,bg:'header',radius:26,align:'center',justify:'center'}),col([T(name,16,600),T(sub,12,400,'muted'),badge(role,'blue')],{grow:1,gap:5})]),...(photoTarget?[button('Profile photo',photoTarget,'secondary')]:[])]);
  const hero = (over,title,meta,actions) => card([T(over.toUpperCase(),10,600,'whiteMuted',{tracking:1.2}),T(title,20,600,'white'),T(meta,13,400,'whiteMuted'),row(actions.map(a=>button(a[0],a[1],'hero')),{gap:10})],{bg:'primary',border:null,padding:20,radius:18,gap:12});
  const navs = {
    patient:[['home','Home','p-home'],['nutrition','Nutrition','p-nutrition'],['calendar','Visits','p-appointments'],['record','Records','p-records'],['user','Profile','p-profile']],
    staff:[['home','Dashboard','s-home'],['users','Patients','s-patients'],['tasks','Tasks','s-tasks'],['calendar','Schedule','s-schedule'],['user','Profile','s-profile']],
    admin:[['home','Dashboard','a-home'],['users','Users','a-users'],['building','Departments','a-departments'],['wallet','Billing','a-billing'],['user','Profile','a-profile']],
  };
  const nav = (role,active) => row(navs[role].map(([icon,label,target],i)=>({...col([I(icon,i===active?'primary':'muted',20),T(label,10,i===active?600:400,i===active?'primary':'muted',{align:'center'})],{grow:1,gap:6,align:'center',padding:[12,0,8,0],bg:i===active?'blueTint':null,radius:12}),target})),{padding:[10,12,20,12],gap:3,bg:'surface',border:'border'});
  const top = (title,over,back,role) => col([
    row([T('9:41',12,600,'ink',{grow:1}),T('•••  ▰',11,600)],{padding:[0,2,6,2]}),
    row([...(back?[{...I('back','ink',22),target:back}]:[]),col([...(over?[T(over,12,400,'muted')]:[]),T(title,24,600,'ink',{family:'Lexend'})],{grow:1,gap:5}),...(role?[{...F('Notifications',[I('bell','primary',20)],{width:48,height:48,bg:'surface',radius:24,justify:'center',align:'center'}),target:({patient:'p',staff:'s',admin:'a'})[role]+'-notifications'},{...F('Preferences',[I('settings','primary',20)],{width:48,height:48,bg:'surface',radius:24,justify:'center',align:'center'}),target:({patient:'p',staff:'s',admin:'a'})[role]+'-preferences'}]:[])],{gap:10}),
  ],{padding:[18,20,22,20],bg:'header',radius:[0,0,24,24],gap:10});
  const authTop = (title,sub) => col([row([F('MyHealth mark',[I('heart','white',24)],{width:38,height:38,bg:'primary',radius:12,align:'center',justify:'center'}),T('MyHealth Care',16,600)]),T(title,26,600,'ink',{family:'Lexend'}),T(sub,14,400,'muted')],{padding:[44,24,28,24],bg:'header',radius:[0,0,28,28],gap:16});

  const readonly = (label,value) => card([row([T(label,12,600,'muted',{grow:1}),I('lock','muted',16)]),T(value,14,500),T('Managed by the administrator',11,400,'muted')],{bg:'blueTint',gap:6});
  const toggle = (label,on,caption) => row([col([T(label,14,500),...(caption?[T(caption,12,400,'muted')]:[])],{grow:1,gap:4}),badge(on?'On':'Off',on?'blue':'amber')],{minHeight:48});
  const preferencesBody = prefix => [
    h('On this device'),T('Shared by people using this browser or device.',12,400,'muted'),
    card([h('Appearance'),chips(['Light','Dark','System'],2)]),
    card([h('Text size'),row([T('A',12,500),F('Size track',[],{height:6,grow:1,bg:'header',radius:3}),T('A',24,500)]),T('Default · five sizes available',12,400,'muted')]),
    card([h('Language'),chips(['System','English','العربية'],0)]),
    card([h('Motion'),chips(['System','Reduced','Full'],0),toggle('High contrast',false),button('Reset appearance',prefix+'-reset-prefs','ghost')]),
    h('For your account'),T('Notification choices are saved for this account on this device.',12,400,'muted'),
    card([toggle('SMS',false,'Unavailable in this prototype'),toggle('Email',false,'Unavailable in this prototype'),toggle('Browser alerts',true),note('Browser permission is required for device alerts.','bell','blue'),toggle('Sounds',true),T('In-app notifications remain available.',12,400,'muted'),button('Reset notifications',prefix+'-reset-prefs','ghost')]),
  ];

  const screens = [];
  function screen(id,role,name,title,body,options={}) {
    const children=[role==='auth'?authTop(title,options.subtitle||'Your health, thoughtfully connected.'):top(title,options.over,options.back,role)];
    children.push(col(body,{padding:20,gap:16,grow:1}));
    if(options.footer) children.push(col(options.footer,{padding:[0,20,20,20],gap:10}));
    if(options.nav!==undefined) children.push(nav(role,options.nav));
    screens.push({id,role,name,width:390,tree:F(name,children,{width:390,minHeight:844,bg:'page',radius:24,direction:'column',gap:0})});
  }
  // AUTH — all entry, registration and recovery states.
  screen('auth-login','auth','01 · Sign in','Welcome back',[
    field('Email or National ID','name@example.com','user'),field('Password','Enter your password','lock','Show'),
    T('Forgot password?',13,600,'primary',{align:'right',target:'auth-recover'}),button('Sign in','p-home'),
    row([F('Line',[],{height:1,grow:1,bg:'border'}),T('New here?',12,400,'muted'),F('Line',[],{height:1,grow:1,bg:'border'})]),
    button('Create patient account','auth-register-1','secondary'),
    card([T('Explore the demo',13,600),T('Use a sample account to take a look around.',12,400,'muted'),row([button('Patient','p-home','ghost'),button('Staff','s-home','ghost'),button('Admin','a-home','ghost')],{gap:6})],{bg:'blueTint',border:null}),
    T('English  ·  العربية',12,500,'muted',{align:'center'}),
  ],{subtitle:'Sign in to your health account.'});
  screen('auth-register-1','auth','02 · Register / account','Create your account',[
    progress(1),T('Step 1 of 3 · Account',12,500,'muted'),field('Full name','Your full name'),field('Email','name@example.com','mail'),field('Password','Choose a strong password','lock','Show'),
    T('At least 8 characters, one number and one uppercase letter.',12,400,'muted'),button('Continue','auth-register-2'),button('Back to sign in','auth-login','ghost'),
  ],{subtitle:'A few details to get you started.'});
  screen('auth-register-2','auth','03 · Register / details','Your details',[
    progress(2),T('Step 2 of 3 · Personal details',12,500,'muted'),field('National ID · optional','Enter your National ID'),field('Date of birth','Select a date','calendar'),field('Gender · optional','Select an option'),field('Phone · optional','+973 0000 0000'),
    button('Continue','auth-register-3'),button('Back','auth-register-1','ghost'),
  ],{subtitle:'Help your care team identify you.'});
  screen('auth-register-3','auth','04 · Register / health','Health information',[
    progress(3),T('Step 3 of 3 · Optional health details',12,500,'muted'),field('Blood type','Select if known','heart'),field('Allergies','Add any known allergies','warning'),field('Chronic conditions','Add any existing conditions','record'),field('Emergency contact','Name and phone number','user'),
    T('You can add or update this information later in Profile.',12,400,'muted'),button('Create account','p-home'),button('Back','auth-register-2','ghost'),
  ],{subtitle:'Share what you know. You can skip optional details.'});
  screen('auth-recover','auth','05 · Recovery / identify','Forgot password?',[
    field('Email or National ID','name@example.com','mail'),button('Continue','auth-code'),
    note('Demo recovery uses a simulated verification inbox.','mail','blue'),button('Back to sign in','auth-login','ghost'),
  ],{subtitle:'Enter your account identifier to start recovery.'});
  screen('auth-code','auth','06 · Recovery / verification','Verify your account',[
    card([I('mail','primary',32),T('Check your verification inbox',18,600),T('If an account matches, a 6-digit code is available in the demo inbox. The code expires after 10 minutes.',14,400,'muted')],{padding:24}),
    field('Verification code','Enter 6-digit code','lock'),note('Simulated inbox · synthetic accounts only','mail','blue'),button('Continue','auth-password'),button('Back to sign in','auth-login','ghost'),
  ],{subtitle:'Keep your account secure.'});
  screen('auth-password','auth','07 · Recovery / new password','Set a new password',[
    field('New password','At least 8 characters','lock','Show'),field('Confirm new password','Repeat your password','lock'),
    col([row([I('check','greenText',16),T('8 or more characters',12,500,'muted')]),row([I('check','greenText',16),T('One number',12,500,'muted')]),row([I('check','greenText',16),T('One uppercase letter',12,500,'muted')])],{gap:10}),
    button('Update password','auth-success'),button('Back','auth-code','ghost'),
  ],{subtitle:'Choose a password you have not used before.'});
  screen('auth-success','auth','08 · Recovery / complete','You’re all set',[
    card([F('Success',[I('check','greenText',32)],{width:72,height:72,bg:'greenTint',radius:36,align:'center',justify:'center'}),T('Password updated',22,600),T('Sign in again with your new password to continue.',14,400,'muted')],{padding:24,gap:20}),button('Back to sign in','auth-login'),
  ],{subtitle:'Your account is ready to use.'});
  screen('auth-help','auth','09 · Recovery / assisted','Recovery assistance',[
    card([I('user','primary',32),T('Contact the administrator',20,600),T('Self-service recovery is unavailable in this build. Ask the administrator to verify your identity and help you recover access.',14,400,'muted')],{padding:24}),button('Back to sign in','auth-login'),
  ],{subtitle:'A clear next step when delivery is unavailable.'});

  // PATIENT — daily overview and complete core task paths.
  screen('p-home','patient','01 · Home','Sara Ahmed',[
    note('Allergy recorded: penicillin','warning','amber'),
    {...row([I('chat','primary'),T('1 new reply from your care team',12,600,'primary',{grow:1}),I('chevron','primary',16)],{bg:'blueTint',padding:12,radius:12}),target:'p-messages'},
    hero('Next appointment','Dr. Omar Khalil','Cardiology · Tomorrow, 10:30 AM · Room 204',[['View ticket','p-ticket'],['Reschedule','p-reschedule']]),
    h('Quick actions'),row([['calendar','Book visit','p-booking'],['chat','Ask doctor','p-messages'],['home','Home care','p-homevisit']].map(([i,label,target])=>({...col([F('Icon',[I(i)],{width:40,height:40,bg:'blueTint',radius:12,align:'center',justify:'center'}),T(label,11,600,'ink',{align:'center'})],{grow:1,padding:12,bg:'surface',border:'border',radius:14,align:'center',gap:10}),target})),{gap:10}),
    h('Your health','View records','p-records'),metrics([['Last visit','12 Sep'],['Medicines','2 active'],['Blood pressure','118/76','mmHg · 1 Oct']]),
  ],{over:'Good morning',nav:0});
  screen('p-appointments','patient','02 · Appointments','Appointments',[
    chips(['Upcoming','Past','Cancelled']),listrow('calendar','Dr. Omar Khalil','Cardiology · Tomorrow, 10:30 AM','Confirmed','green','p-ticket'),listrow('calendar','Dr. Lina Haddad','Dermatology · 5 Oct, 2:00 PM','Booked','blue','p-ticket'),listrow('calendar','Dr. Yusuf Nasser','General practice · 8 Oct, 9:15 AM','Confirmed','green','p-ticket'),
    T('Your appointment details and available actions are inside each ticket.',12,400,'muted'),button('Book an appointment','p-booking'),
  ],{nav:2});
  screen('p-ticket','patient','03 · Appointment ticket','Your appointment',[
    card([row([T('VISIT TICKET',11,600,'muted',{grow:1,tracking:1}),badge('Confirmed')]),T('A-1042',32,600,'primary',{family:'Lexend'}),divider(),T('Dr. Omar Khalil',20,600),T('Cardiology · Follow-up visit',14,400,'muted'),row([I('calendar'),T('Saturday, 3 Oct 2026',14,600)]),row([I('clock'),T('10:30 AM · 30 minutes',14,600)]),row([I('building'),T('Room 204 · Main clinic',14,600)])],{padding:24,gap:16}),
    note('Please arrive 10 minutes before your appointment.','clock','blue'),button('Reschedule appointment','p-reschedule','secondary'),button('Cancel appointment','p-cancel','ghost'),
  ],{back:'p-appointments',footer:[button('Add to calendar','p-ticket','secondary'),button('Contact support','p-feedback','ghost')]});
  screen('p-booking','patient','04 · Book / choose','Book a visit',[
    progress(1,3),T('Step 1 of 3 · Choose a clinician',12,500,'muted'),note('Booking for Sara Ahmed','user','blue'),field('Department','Cardiology','building'),h('Available clinicians'),
    listrow('user','Dr. Omar Khalil','Next opening · Tomorrow, 10:30 AM','Selected','blue','p-slot'),listrow('user','Dr. Maryam Ali','Next opening · Monday, 9:00 AM',null,'green','p-slot'),field('Reason for visit','Follow-up','record'),
  ],{back:'p-appointments',footer:[button('Choose a time','p-slot')]});
  screen('p-slot','patient','05 · Book / time','Choose a time',[
    progress(2,3),T('Step 2 of 3 · Date and time',12,500,'muted'),listrow('user','Dr. Omar Khalil','Cardiology',null,'green','p-booking'),field('Appointment date','Saturday, 3 Oct 2026','calendar'),h('Available times'),
    row(['9:00','9:30','10:00'].map(s=>button(s,'p-review','secondary')),{gap:8}),row([button('10:30','p-review'),button('11:00','p-review','secondary'),button('11:30','p-review','secondary')],{gap:8}),
    T('Times are shown in the clinic’s local time. Availability is checked again when you confirm.',12,400,'muted'),
  ],{back:'p-booking',footer:[button('Review appointment','p-review')]});
  screen('p-review','patient','06 · Book / review','Review your visit',[
    progress(3,3),T('Step 3 of 3 · Confirm',12,500,'muted'),card([h('Booking for'),T('Sara Ahmed',18,600),divider(),T('Dr. Omar Khalil',18,600),T('Cardiology · Follow-up',14,400,'muted'),row([I('calendar'),T('3 Oct 2026 · 10:30 AM',14,600)]),row([I('building'),T('Main clinic · Room 204',14,500)])],{padding:24,gap:16}),note('You will see a ticket once the booking is confirmed.','check','blue'),
  ],{back:'p-slot',footer:[button('Confirm appointment','p-confirmed'),button('Edit details','p-booking','ghost')]});
  screen('p-confirmed','patient','07 · Book / success','Visit confirmed',[
    card([F('Confirmed',[I('check','greenText',32)],{width:72,height:72,bg:'greenTint',radius:36,justify:'center',align:'center'}),T('You’re booked',24,600),T('Dr. Omar Khalil · Cardiology',15,600),T('3 Oct 2026 · 10:30 AM · Room 204',13,400,'muted')],{padding:24,gap:20}),button('View appointment ticket','p-ticket'),button('Back to home','p-home','secondary'),
  ],{back:'p-home'});
  screen('p-cancel','patient','08 · Appointment / cancel','Cancel this visit?',[
    listrow('calendar','Dr. Omar Khalil','3 Oct 2026 · 10:30 AM','Confirmed','green','p-ticket'),card([T('This appointment will be cancelled.',18,600),T('Your reminder will also be removed. You can book another visit when you’re ready.',14,400,'muted')]),button('Keep my appointment','p-ticket'),button('Confirm cancellation','p-appointments','secondary'),
  ],{back:'p-ticket'});
  screen('p-records','patient','09 · Health records','Health records',[
    search('Search records or lab values'),chips(['All','Lab','Imaging','Notes']),listrow('lab','Blood test results','12 Sep 2026 · Lab','Reviewed','green','p-result'),listrow('record','Cardiology consultation','14 Aug 2026 · Dr. Omar Khalil','New','blue','p-result'),listrow('record','Chest X-ray','28 Aug 2026 · Imaging','Reviewed','green','p-result'),
    h('More health information'),row([button('Medications','p-medications','secondary'),button('Vital signs','p-vitals','secondary')],{gap:10}),button('Import a document','p-import','secondary'),
  ],{nav:3});
  screen('p-result','patient','10 · Lab result detail','Blood test results',[
    card([T('12 September 2026',12,500,'muted'),T('Routine blood panel',20,600),row([badge('Reviewed'),T('Dr. Omar Khalil',12,500,'muted')])]),
    h('Results'),card([row([T('HbA1c',14,600,{grow:1}),badge('In range')]),T('5.4 %',26,600,'ink'),T('Reference range · 4.0–5.6 %',12,400,'muted'),divider(),row([T('Hemoglobin',14,600,'ink',{grow:1}),badge('In range')]),T('13.2 g/dL',26,600),T('Reference range · 12.0–15.5 g/dL',12,400,'muted')]),
    note('Values and ranges come from this report.','record','blue'),button('Open original document','p-result','secondary'),
  ],{back:'p-records',footer:[button('Download PDF','p-result','secondary')]});
  screen('p-medications','patient','11 · Medications','Medications',[
    chips(['Current','Past']),card([row([I('pill'),T('Amlodipine',16,600,'ink',{grow:1}),badge('Active')]),T('5 mg · Once daily',14,500),T('Prescribed by Dr. Omar Khalil',12,400,'muted')]),card([row([I('pill'),T('Vitamin D',16,600,'ink',{grow:1}),badge('Active')]),T('1,000 IU · Once daily',14,500),T('Prescribed by Dr. Omar Khalil',12,400,'muted')]),note('Follow the instructions from your care team.','record','blue'),
  ],{back:'p-records'});
  screen('p-vitals','patient','12 · Vital signs','Vital signs',[
    h('Latest measurements'),metrics([['Blood pressure','118/76','mmHg'],['Heart rate','72','bpm']]),metrics([['Weight','64.2','kg'],['Temperature','36.6','°C']]),T('Recorded 1 Oct 2026 at 9:20 AM',12,400,'muted'),h('Previous readings'),listrow('heart','Blood pressure · 120/78 mmHg','18 Sep 2026',null,'green','p-vitals'),listrow('heart','Blood pressure · 119/77 mmHg','5 Sep 2026',null,'green','p-vitals'),button('Download vital signs report','p-vitals','secondary'),
  ],{back:'p-records'});
  screen('p-import','patient','13 · Import record','Add a health document',[
    card([F('Upload',[I('download','primary',32)],{width:64,height:64,bg:'blueTint',radius:16,align:'center',justify:'center'}),T('Choose a PDF document',20,600),T('Attach a report to your personal health records.',14,400,'muted'),button('Choose file','p-import','secondary')],{padding:24,gap:20}),field('Document title','Blood test report','record'),field('Document date','12 Sep 2026','calendar'),note('Imported values remain unverified until reviewed.','warning','amber'),
  ],{back:'p-records',footer:[button('Import document','p-records')]});
  screen('p-nutrition','patient','14 · Nutrition overview','Nutrition',[
    note('Estimated targets · not a meal diary','nutrition','blue'),card([h('Daily calorie estimate','Edit','p-nutrition-edit'),T('2,000 kcal',30,600,'primary',{family:'Lexend'}),T('Based on your saved activity and goal.',12,400,'muted'),divider(),metrics([['Protein','100 g'],['Carbs','250 g'],['Fat','67 g']])],{padding:20}),h('Example daily split'),listrow('nutrition','Breakfast','Example portion · 500 kcal',null,'green','p-nutrition'),listrow('nutrition','Lunch','Example portion · 700 kcal',null,'green','p-nutrition'),listrow('nutrition','Dinner & snack','Example portions · 800 kcal',null,'green','p-nutrition'),button('Explore foods','p-foods','secondary'),
  ],{over:'Your estimated daily targets',nav:1});
  screen('p-nutrition-edit','patient','15 · Nutrition / inputs','Your nutrition inputs',[
    field('Age','42 years'),row([field('Weight','64.2 kg','heart'),field('Height','165 cm','heart')],{gap:12}),field('Activity level','Moderately active','heart'),field('Goal','Maintain weight','nutrition'),field('Calculation category','Female'),T('These inputs estimate your energy and macro targets. They do not prescribe a diet.',12,400,'muted'),
  ],{back:'p-nutrition',footer:[button('Calculate targets','p-nutrition')]});
  screen('p-foods','patient','16 · Nutrition / foods','Explore foods',[
    search('Search foods'),chips(['All','Protein','Fruit','Grains']),listrow('nutrition','Greek yogurt','Per 100 g · 59 kcal · 10 g protein',null,'green','p-foods'),listrow('nutrition','Chicken breast','Per 100 g · 165 kcal · 31 g protein',null,'green','p-foods'),listrow('nutrition','Oats','Per 100 g · 389 kcal · 17 g protein',null,'green','p-foods'),note('Check ingredients against your recorded allergies.','warning','amber'),
  ],{back:'p-nutrition'});
  screen('p-profile','patient','17 · Profile','Profile',[
    identity('Sara Ahmed','sara@example.com','Patient','p-photo'),h('Account'),menu([['user','Personal information','p-personal'],['heart','Health details','p-health'],['users','Family & linked accounts','p-family'],['wallet','Payments & billing','p-payments'],['lock','Change password','p-password']]),h('Settings'),menu([['settings','Preferences','p-preferences'],['chat','Send feedback','p-feedback']]),menu([['logout','Sign out','auth-login',true]]),
  ],{nav:4});
  screen('p-personal','patient','18 · Personal information','Personal information',[
    field('First name','Sara'),field('Last name','Ahmed'),readonly('Email','sara@example.com'),field('Phone','+973 3333 0000'),field('Date of birth','18/05/1984','calendar'),field('Gender','Female'),readonly('National ID','••••••123'),button('Cancel changes','p-profile','secondary'),
  ],{back:'p-profile',footer:[button('Save changes','p-profile')]});
  screen('p-health','patient','19 · Health details','Health details',[
    field('Blood type','O+','heart'),field('Known allergies','Penicillin','warning'),field('Chronic conditions','Hypertension','record'),field('Emergency contact','Ahmed Ali · +973 3333 1000','user'),note('Keep this information current for your care team.','record','blue'),
  ],{back:'p-profile',footer:[button('Save changes','p-profile')]});
  screen('p-family','patient','20 · Family access','Family & linked accounts',[
    note('Each linked person controls the access they grant.','lock','blue'),h('Accounts you can access'),listrow('user','Ahmed Ali','View-only access','Linked','blue','p-linked'),listrow('user','Layla Ahmed','Manage access','Linked','green','p-linked'),h('Pending requests'),listrow('user','Mariam Ali','Requests view-only access','Pending','amber','p-linked'),button('Request an account link','p-family-request','secondary'),button('Review pending request','p-family-consent','secondary'),h('Family members without accounts'),listrow('user','Layla Ahmed','Child · Family member',null,'green','p-family-member'),button('Add family member','p-family-member','secondary'),button('Who can view my account','p-family-revoke','ghost'),
  ],{back:'p-profile'});
  screen('p-linked','patient','21 · Linked account','Ahmed Ali',[
    note('Viewing Ahmed’s account · view-only access','lock','blue'),identity('Ahmed Ali','Family account','View only'),h('Health information'),listrow('calendar','Next appointment','8 Oct 2026 · Dr. Yusuf Nasser','Confirmed','green'),listrow('record','Latest record','Blood panel · 18 Sep 2026','Reviewed','green'),T('Booking and editing are available only when this account grants manage access.',13,400,'muted'),button('Back to my account','p-family','secondary'),
  ],{back:'p-family'});
  screen('p-preferences','patient','22 · Preferences','Preferences',preferencesBody('p'),{back:'p-profile'});
  screen('p-payments','patient','23 · Payments overview','Payments & billing',[
    card([T('Outstanding balance',12,500,'muted'),T('BD 35.00',32,600,'primary',{family:'Lexend'}),T('1 invoice awaiting payment',12,400,'muted'),button('View and pay invoice','p-pay')],{padding:20}),h('Invoices'),listrow('wallet','Consultation · INV-1042','Due 5 Oct 2026 · BD 35.00','Unpaid','amber','p-pay'),listrow('wallet','Lab panel · INV-1031','Paid 12 Sep 2026 · BD 20.00','Paid','green','p-payments'),h('Your wallet'),card([row([T('Available balance',14,500,'ink',{grow:1}),T('BD 10.00',18,600)]),button('Top up wallet','p-topup','secondary'),button('Payment methods','p-methods','secondary'),button('Transaction history','p-pay-history','ghost')]),
  ],{back:'p-profile'});
  screen('p-pay','patient','24 · Pay invoice','Pay your invoice',[
    card([T('Consultation · INV-1042',14,600),T('BD 35.00',32,600,'primary'),T('Dr. Omar Khalil · 3 Oct 2026',12,400,'muted')],{padding:24}),h('Payment method'),listrow('wallet','Demo card · •••• 4242','Expires 12/28','Selected','blue','p-pay'),listrow('wallet','Wallet · BD 10.00','Insufficient balance',null,'green','p-pay'),note('Demo payment · no real money is charged','wallet','blue'),
  ],{back:'p-payments',footer:[button('Pay BD 35.00','p-payment-pending')]});
  screen('p-payment-pending','patient','25 · Payment pending','Checking your payment',[
    card([F('Pending',[I('clock','amberText',32)],{width:72,height:72,bg:'amberTint',radius:36,justify:'center',align:'center'}),T('Payment not yet confirmed',21,600),T('BD 35.00 · INV-1042',15,600),T('You have not been asked to pay again. Check the payment status before trying another method.',14,400,'muted')],{padding:24,gap:20}),button('Check payment status','p-payments'),button('Back to invoices','p-payments','secondary'),
  ],{back:'p-payments'});
  screen('p-messages','patient','26 · Care messages','Your care team',[
    note('For non-emergency questions. Replies are expected within one working day.','chat','blue'),listrow('chat','Dr. Omar Khalil','Your follow-up plan is ready.','1 new','blue','p-thread'),listrow('chat','Dr. Lina Haddad','Last message · 12 Sep 2026',null,'green','p-thread'),button('Start a message','p-thread','secondary'),
  ],{back:'p-home'});
  screen('p-thread','patient','27 · Message thread','Dr. Omar Khalil',[
    T('Care team · Cardiology',12,500,'muted'),note('This is not an emergency channel.','warning','amber'),T('Today',11,500,'muted',{align:'center'}),card([T('Hello doctor, should I bring my latest blood test to the follow-up?',14,400)],{bg:'header',border:null}),card([T('Yes, please bring the latest report. We can go through it together at your appointment.',14,400),T('Dr. Omar Khalil · 9:15 AM',11,400,'muted')]),
  ],{back:'p-messages',footer:[field('Message','Write your question…','chat'),button('Send message','p-thread')]});
  screen('p-homevisit','patient','28 · Home care request','Request home care',[
    T('Request a visit for review by the clinic team.',14,400,'muted'),field('Home address','Building, road and block','home'),field('Preferred date','Choose a date','calendar'),field('Department · optional','Choose a department','building'),field('Reason for request','Describe what help you need','record'),note('The clinic must review and arrange the visit before it is confirmed.','clock','blue'),
  ],{back:'p-home',footer:[button('Send request','p-home')]});

  // STAFF — task-first workspace and clinical continuity.
  screen('s-home','staff','01 · Dashboard','Dr. Omar Khalil',[
    row([badge('On duty'),T('Cardiology',12,500,'muted',{grow:1}),T('Change',12,600,'primary')]),
    hero('Next patient','Sara Ahmed · 10:30 AM','Checked in · Room 204 · Follow-up',[['Start visit','s-consultation'],['Open chart','s-chart']]),metrics([['In queue','6'],['To review','2'],['Tasks due','4']]),
    h('Needs your attention','View all','s-tasks'),listrow('lab','Ahmed Saleh · Result review','HbA1c · Due 10:00 AM','Overdue','red','s-result'),listrow('chat','Mona Adel · Awaiting reply','You are covering Dr. Lina Haddad','Today','amber','s-inbox'),
    row([button('Open schedule','s-schedule','secondary'),button('More actions','s-tools','secondary')],{gap:10}),
  ],{over:'Good morning',nav:0});
  screen('s-patients','staff','02 · Patients','Patients',[
    search('Search name or National ID'),chips(['My patients','Flagged','All allowed']),listrow('user','Sara Ahmed','42 · Female · Hypertension','Today','blue','s-chart'),listrow('user','Ahmed Saleh','58 · Male · Diabetes','Flagged','red','s-chart'),listrow('user','Mona Adel','35 · Female · Asthma','Follow-up','amber','s-chart'),listrow('user','Khaled Omar','67 · Male · Cardiology','Scheduled','blue','s-chart'),
  ],{nav:1});
  screen('s-chart','staff','03 · Patient chart','Sara Ahmed',[
    T('42 · Female · ID ending 123 · O+',12,500,'muted'),note('Allergy: penicillin','warning','red'),chips(['Overview','Records','Medicines']),metrics([['BP','118/76','mmHg'],['Pulse','72','bpm'],['Weight','64.2','kg']]),h('Active medications'),listrow('pill','Amlodipine · 5 mg','Once daily','Active','green','s-chart'),h('Latest records'),listrow('lab','Routine blood panel','12 Sep 2026','Reviewed','green'),listrow('record','Consultation note','14 Aug 2026 · Dr. Omar Khalil',null,'green','s-consultation'),
  ],{back:'s-patients',footer:[button('Open consultation','s-consultation')]});
  screen('s-consultation','staff','04 · Consultation','Sara Ahmed',[
    row([badge('In progress','blue'),T('Follow-up · Room 204',12,500,'muted')]),note('Allergy: penicillin','warning','red'),
    row([I('check','greenText',16),T('Draft saved · 10:42 AM',12,500,'greenText',{grow:1}),T('Preview',12,600,'primary')]),
    h('Clinical note'),card([T('Reason for visit',12,600,'muted'),T('Routine follow-up for hypertension.',14,400),divider(),T('Assessment & plan',12,600,'muted'),T('Blood pressure reviewed. Continue current medication and arrange follow-up.',14,400)],{minHeight:180}),
    row([button('Medications','s-chart','secondary'),button('Referral','s-referral','secondary')],{gap:10}),T('Review the note before signing. Signed notes are amended rather than overwritten.',12,400,'muted'),
  ],{back:'s-chart',footer:[button('Review & sign visit','s-signed'),button('Save draft & return','s-chart','ghost')]});
  screen('s-referral','staff','04b · Create referral','Refer Sara Ahmed',[
    note('Referral for Sara Ahmed · ID ending 123','user','blue'),field('Destination department','Dermatology','building'),field('Reason for referral','Describe the clinical question','record'),field('Priority','Routine','clock'),T('The administration team will arrange the referral. Your clinical note stays with the patient chart.',13,400,'muted'),button('Submit referral','s-chart'),button('Back to consultation','s-consultation','secondary'),
  ],{back:'s-consultation'});
  screen('s-signed','staff','05 · Consultation signed','Visit completed',[
    card([F('Signed',[I('check','greenText',32)],{width:72,height:72,bg:'greenTint',radius:36,align:'center',justify:'center'}),T('Note signed and saved',22,600),T('Sara Ahmed · Follow-up',16,600),T('The visit is complete. Medication orders and the signed note are filed in the patient’s chart.',14,400,'muted')],{padding:24,gap:20}),button('Return to queue','s-home'),button('Open patient chart','s-chart','secondary'),
  ],{back:'s-chart'});
  screen('s-result','staff','06 · Result review','Review lab result',[
    card([T('Ahmed Saleh',19,600),T('Blood panel · 1 Oct 2026',12,400,'muted'),row([badge('Overdue','red'),badge('Assigned','blue')]),T('Owner · Dr. Omar Khalil',12,500,'muted')]),card([h('HbA1c'),T('8.2 %',30,600,'redText'),T('Lab reference · 4.0–5.6 %',13,400,'muted'),T('Source: imported lab report · unverified',12,400,'muted')]),field('Review outcome','Record your review and next step','record'),row([button('Escalate','s-handover','secondary'),button('Hand over','s-handover','secondary')],{gap:10}),
  ],{back:'s-home',footer:[button('Mark reviewed','s-home')]});
  screen('s-handover','staff','06b · Handover / escalate','Hand over result review',[
    identity('Ahmed Saleh','Abnormal HbA1c · 1 Oct 2026','Review pending'),chips(['Hand over','Escalate']),field('Receiving clinician','Select an active clinician','user'),field('Priority','Urgent review','warning'),field('Clinical context','Add the reason and required next step','record'),note('You remain responsible until the receiving clinician accepts the handover.','lock','blue'),button('Request handover','s-tasks'),button('Keep reviewing','s-result','secondary'),
  ],{back:'s-result'});
  screen('s-tasks','staff','07 · Task board','Tasks',[
    chips(['Open','In progress','Closed']),T('Ordered by urgency and due time',12,400,'muted'),
    card([row([I('lab'),T('Review abnormal result',15,600,'ink',{grow:1}),badge('Overdue','red')]),T('Ahmed Saleh · HbA1c · Due today',12,500,'muted'),button('Open result review','s-result'),T('Why this is prioritized',12,600,'primary')]),
    card([row([I('record'),T('Complete unsigned note',15,600,'ink',{grow:1}),badge('Today','amber')]),T('Sara Ahmed · Follow-up visit',12,500,'muted'),button('Continue note','s-consultation','secondary')]),
    card([row([I('tasks'),T('Referral follow-up',15,600,'ink',{grow:1}),badge('Tomorrow','blue')]),T('Mona Adel · Assigned to you',12,500,'muted'),button('Open task','s-chart','secondary')]),
  ],{nav:2});
  screen('s-schedule','staff','08 · Schedule','Schedule',[
    row([T('October 2026',16,600,'ink',{grow:1}),T('Today',12,600,'primary'),I('calendar','primary',20)]),
    row([['Mon','28'],['Tue','29'],['Wed','30'],['Thu','1'],['Fri','2']].map(([d,n],i)=>col([T(d,10,500,i===4?'whiteMuted':'muted',{align:'center'}),T(n,18,600,i===4?'white':'ink',{align:'center'})],{grow:1,bg:i===4?'primary':'surface',padding:10,radius:12,align:'center',gap:4})),{gap:7}),
    note('Friday, 2 October · 4 visits','calendar','blue'),
    row([T('09:00',12,600,'primary',{width:46}),listrow('user','Khaled Omar','Check-up · 20 min','Done','green','s-chart')],{gap:10}),
    row([T('10:30',12,600,'primary',{width:46}),listrow('user','Sara Ahmed','Follow-up · 30 min','Arrived','blue','s-consultation')],{gap:10}),
    row([T('11:15',12,600,'primary',{width:46}),listrow('user','Mona Adel','Consultation · 30 min','Booked','blue','s-chart')],{gap:10}),
    row([T('13:00',12,600,'primary',{width:46}),listrow('user','Ahmed Saleh','Lab review · 20 min','Booked','blue','s-result')],{gap:10}),
  ],{nav:3});
  screen('s-inbox','staff','09 · Staff inbox','Care inbox',[
    chips(['Mine','Covering','All allowed']),listrow('chat','Mona Adel','Covering Dr. Lina Haddad','Overdue','red','s-thread'),listrow('chat','Sara Ahmed','Follow-up question · 9:00 AM','Today','amber','s-thread'),listrow('chat','Ahmed Saleh','Lab report question','Today','blue','s-thread'),
  ],{back:'s-home'});
  screen('s-thread','staff','10 · Covered thread','Mona Adel',[
    note('Covering Dr. Lina Haddad · due today','user','blue'),T('Today',11,500,'muted',{align:'center'}),card([T('Hello, I have uploaded my report. Can you review it before my appointment?',14,400)]),card([T('You are replying as the covering clinician. Your reply is recorded in this patient’s existing thread.',13,400,'muted')],{bg:'blueTint',border:null}),
  ],{back:'s-inbox',footer:[field('Reply','Write your reply…','chat'),button('Send reply','s-inbox')]});
  screen('s-profile','staff','11 · Staff profile','Profile',[
    identity('Dr. Omar Khalil','Cardiology','Doctor'),menu([['user','Account','s-account'],['clock','My activity','s-activity'],['users','Staff directory','s-directory'],['chart','Panel analytics','s-analytics'],['settings','Preferences','s-preferences']]),menu([['chat','Send feedback','s-feedback'],['logout','Sign out','auth-login',true]]),
  ],{nav:4});
  screen('s-preferences','staff','12 · Staff preferences','Preferences',preferencesBody('s'),{back:'s-profile'});

  // ADMIN — ownership, correction and quieter operational lists.
  screen('a-home','admin','01 · Dashboard','Admin workspace',[
    hero('Needs your attention','8 items need a review','Results, payment checks and care requests',[['Open work queue','a-work']]),
    h('Work needing attention'),listrow('lab','Results without an owner','Oldest item · 2 hours','2','red','a-work'),listrow('wallet','Payments to confirm','Oldest item · 35 minutes','3','amber','a-billing'),listrow('record','Referral requests','Oldest item · yesterday','2','blue','a-referrals'),listrow('home','Home visit requests','Oldest item · today','1','blue','a-homevisits'),
    h('Recent activity','Audit log','a-audit'),T('Dr. Lina Haddad updated her availability · 10 min ago',12,400,'muted'),
  ],{over:'Friday, 2 October',nav:0});
  screen('a-work','admin','02 · Work queue','Work needing attention',[
    search('Search patient or work item'),chips(['Results','Messages','Delivery']),row([button('Owner: All','a-work','secondary'),button('Status: Open','a-work','secondary')],{gap:10}),
    card([row([T('Ahmed Saleh',15,600,'ink',{grow:1}),badge('Overdue','red')]),T('Abnormal lab result · waiting 2 hours',12,400,'muted'),T('Owner · Unassigned',12,600,'redText'),button('Assign owner','a-assign')]),
    card([row([T('Mona Adel',15,600,'ink',{grow:1}),badge('Needs reply','amber')]),T('Care message · waiting 1 working day',12,400,'muted'),T('Owner · Dr. Lina Haddad',12,500,'muted'),button('Review coverage','a-assign','secondary')]),
  ],{back:'a-home'});
  screen('a-assign','admin','03 · Assign work','Assign result review',[
    listrow('lab','Ahmed Saleh','Abnormal lab result · HbA1c','Overdue','red','a-work'),field('Assign to','Dr. Omar Khalil','user'),field('Priority','Priority review','warning'),field('Handover note','Add context for the next owner','record'),note('Only an active doctor can own this result review.','lock','blue'),
  ],{back:'a-work',footer:[button('Assign review','a-work')]});
  screen('a-users','admin','04 · User directory','Users',[
    search('Search name or email'),chips(['Patients','Staff','Admins'],1),listrow('user','Dr. Omar Khalil','Cardiology · On duty','Active','green','a-user'),listrow('user','Dr. Lina Haddad','Dermatology · Off shift','Active','green','a-user'),listrow('user','Dr. Yusuf Nasser','General practice','Inactive','red','a-user'),listrow('user','Nurse Huda Ali','Emergency · On duty','Active','green','a-user'),button('Add staff member','a-create'),button('Add patient','a-create-patient','secondary'),
  ],{nav:1});
  screen('a-user','admin','05 · Staff account','Staff account',[
    identity('Dr. Omar Khalil','omar@myhealth.demo','Doctor'),metrics([['Account','Active'],['Presence','On duty']]),menu([['user','Account information','a-user'],['building','Department · Cardiology','a-user'],['calendar','Schedule templates','a-staff-schedule'],['lock','Recovery requests','a-user']]),button('Schedule templates','a-staff-schedule','secondary'),button('Deactivate account','a-user','ghost'),
  ],{back:'a-users'});
  screen('a-create','admin','06 · Create staff','Add staff member',[
    field('Full name','Enter full name'),field('Email','name@myhealth.demo','mail'),field('Clinical role','Doctor','user'),field('Department','Choose department','building'),field('Temporary password','Set a temporary password','lock','Show'),note('Role determines which clinical actions are available.','lock','blue'),
  ],{back:'a-users',footer:[button('Create staff account','a-users')]});
  screen('a-departments','admin','07 · Departments','Departments',[
    listrow('building','Cardiology','Heart and vascular care',null,'green','a-department'),listrow('building','Dermatology','Skin health',null,'green','a-department'),listrow('building','General practice','Primary care',null,'green','a-department'),listrow('building','Emergency','Urgent clinical assessment',null,'green','a-department'),button('New department','a-department'),
  ],{nav:2});
  screen('a-department','admin','08 · Edit department','Department details',[
    field('Department name','Cardiology','building'),field('Description','Heart and vascular care','record'),note('Departments with linked records may not be deleted.','lock','blue'),button('Save department','a-departments'),button('Delete department','a-departments','ghost'),
  ],{back:'a-departments'});
  screen('a-billing','admin','09 · Billing overview','Billing',[
    search('Search patient or invoice'),chips(['All','Unpaid','Paid','Refunded']),T('Demo billing · amounts shown in BD',12,500,'muted'),listrow('wallet','Sara Ahmed · BD 35.00','INV-1042 · Due 5 Oct 2026','Unpaid','amber','a-invoice'),listrow('wallet','Ahmed Saleh · BD 20.00','INV-1041 · Paid 28 Sep 2026','Paid','green','a-invoice'),listrow('wallet','Mona Adel · BD 40.00','INV-1040 · Payment being checked','Pending','blue','a-invoice'),button('Check pending payments','a-invoice','secondary'),
  ],{nav:3});
  screen('a-invoice','admin','10 · Invoice & ledger','Invoice INV-1042',[
    card([row([T('Sara Ahmed',18,600,'ink',{grow:1}),badge('Unpaid','amber')]),T('BD 35.00',32,600,'primary'),T('Consultation · Due 5 Oct 2026',13,400,'muted')],{padding:24}),h('Payment history'),card([T('No settled payment yet.',14,500),T('An invoice is paid only after its transaction is confirmed.',12,400,'muted')]),button('Record desk payment','a-desk','secondary'),button('Check payment status','a-reconcile','secondary'),button('Refund settled payment','a-refund','secondary'),T('Refunds are available for settled transactions and require a reason.',12,400,'muted'),
  ],{back:'a-billing'});
  screen('a-desk','admin','11 · Desk payment','Record desk payment',[
    listrow('wallet','Sara Ahmed · INV-1042','Outstanding · BD 35.00',null,'green','a-invoice'),field('Receipt number','Enter receipt number','record'),field('Payment note · optional','Add a note','record'),note('This records a payment transaction and updates the invoice after settlement.','wallet','blue'),
  ],{back:'a-invoice',footer:[button('Record BD 35.00 payment','a-billing')]});
  screen('a-referrals','admin','12 · Referral requests','Referral requests',[
    chips(['Pending','Arranged','Closed']),card([row([T('Mona Adel',16,600,'ink',{grow:1}),badge('Pending','amber')]),T('Dr. Omar Khalil → Dermatology',12,500,'muted'),T('Requested yesterday · Owner: Admin',12,400,'muted'),button('Review request','a-referral')]),card([row([T('Khaled Omar',16,600,'ink',{grow:1}),badge('Pending','amber')]),T('Dr. Yusuf Nasser → Cardiology',12,500,'muted'),T('Requested today · Owner: Admin',12,400,'muted'),button('Review request','a-referral','secondary')]),
  ],{back:'a-home'});
  screen('a-referral','admin','13 · Review referral','Review referral',[
    identity('Mona Adel','Requested by Dr. Omar Khalil','Pending referral'),field('Destination','Dermatology','building'),field('Assigned owner','Admin','user'),field('Decision note','Record the arrangement or next step','record'),button('Arrange referral','a-referrals'),button('Request clarification','a-referrals','secondary'),button('Reject with reason','a-referrals','ghost'),
  ],{back:'a-referrals'});
  screen('a-homevisits','admin','14 · Home visit queue','Home visit requests',[
    chips(['Pending','Scheduled','Completed']),card([row([T('Sara Ahmed',16,600,'ink',{grow:1}),badge('Pending','amber')]),T('Preferred date · 6 Oct 2026',12,500,'muted'),T('Reason · Follow-up support at home',13,400,'muted'),button('Review & schedule','a-homevisits'),button('Decline with reason','a-homevisits','ghost')]),
  ],{back:'a-home'});
  screen('a-profile','admin','15 · Admin profile','Profile',[
    identity('Administrator','admin@myhealth.demo','Administrator'),menu([['user','Account','a-account'],['chart','System analytics','a-analytics'],['chart','Capacity forecast','a-forecast'],['clock','AI activity','a-ai-log'],['record','Audit log','a-audit'],['settings','AI settings','a-ai'],['calendar','Clinic hours','a-hours'],['settings','Preferences','a-preferences']]),menu([['logout','Sign out','auth-login',true]]),
  ],{nav:4});
  screen('a-analytics','admin','16 · Analytics','System analytics',[
    chips(['30 days','90 days','Custom'],1),note('Historical activity · not a forecast','chart','blue'),metrics([['Completed','186'],['Cancelled','14']]),metrics([['No-show rate','8%'],['Active staff','12']]),h('Demand by weekday'),card([['Monday',70],['Tuesday',90],['Wednesday',55],['Thursday',80],['Friday',38]].map(([label,val])=>row([T(label,12,500,'muted',{width:76}),F('Bar',[],{height:10,width:val*1.8,bg:'primary',radius:5})],{gap:12})),{gap:16}),T('Example synthetic data · calculated 2 Oct 2026',11,400,'muted'),
  ],{back:'a-profile'});
  screen('a-audit','admin','17 · Audit log','Audit log',[
    search('Search actor or event'),chips(['All','Accounts','Clinical','Billing']),listrow('record','Result assigned','Admin → Dr. Omar Khalil · 10:40 AM',null,'green','a-audit'),listrow('wallet','Desk payment recorded','INV-1031 · 10:20 AM',null,'green','a-invoice'),listrow('user','Staff availability updated','Dr. Lina Haddad · 10:05 AM',null,'green','a-user'),listrow('calendar','Appointment rescheduled','A-1042 · 9:45 AM',null,'green','a-audit'),
  ],{back:'a-profile'});
  screen('a-hours','admin','18 · Clinic hours','Clinic hours',[
    h('Open days'),chips(['Sun','Mon','Tue','Wed']),chips(['Thu','Fri','Sat'],0),row([field('Opens','08:00','clock'),field('Closes','17:00','clock')],{gap:12}),note('Clinic hours affect which appointment times can be booked.','calendar','blue'),button('Save clinic hours','a-profile'),
  ],{back:'a-profile'});
  screen('a-ai','admin','19 · AI settings','AI settings',[
    note('Live clinical AI is disabled in this prototype.','lock','amber'),card([h('Current mode'),badge('Demo / offline','blue'),T('Draft content is for human review. Core booking and chart workflows work without AI.',14,400,'muted')]),menu([['record','AI activity log','a-ai-log'],['settings','Provider configuration','a-ai']]),T('API keys are entered securely in the app. No credentials appear in this design.',12,400,'muted'),
  ],{back:'a-profile'});
  screen('a-preferences','admin','20 · Admin preferences','Preferences',preferencesBody('a'),{back:'a-profile'});

  // Representative states are grouped in the same role area, not separate files.
  screen('p-empty','patient','29 · State / no appointments','Appointments',[
    chips(['Upcoming','Past','Cancelled']),card([F('Empty',[I('calendar','primary',32)],{width:72,height:72,bg:'blueTint',radius:24,justify:'center',align:'center'}),T('No upcoming visits',22,600),T('When you book a visit, your appointment and ticket will appear here.',14,400,'muted'),button('Book a visit','p-booking')],{padding:24,gap:20}),
  ],{nav:2});
  screen('p-error','patient','30 · State / wallet failure','Payments & billing',[
    note('Could not load your wallet balance.','warning','red'),card([T('We couldn’t check your balance',20,600),T('Your balance is unavailable. Try again to load the latest value.',14,400,'muted'),button('Try again','p-payments')],{padding:24,gap:20}),listrow('wallet','Consultation · INV-1042','Due 5 Oct 2026 · BD 35.00','Unpaid','amber','p-pay'),
  ],{back:'p-profile'});
  screen('s-error','staff','13 · State / save failure','Sara Ahmed',[
    badge('In progress','blue'),note('Draft not saved. Your text is still here.','warning','red'),h('Clinical note'),card([T('Routine follow-up for hypertension.',14,400),T('Blood pressure reviewed. Continue current medication and arrange follow-up.',14,400)],{minHeight:220}),button('Retry save','s-consultation'),button('Stay on this visit','s-consultation','secondary'),
  ],{back:'s-chart'});
  screen('a-error','admin','21 · State / queue failure','Admin workspace',[
    note('Some queues could not be checked.','warning','red'),card([T('Result review queue unavailable',18,600),T('We cannot confirm whether results need an owner.',14,400,'muted'),button('Retry queue check','a-home')]),h('Queues checked successfully'),listrow('wallet','Payments to confirm','3 pending transactions','3','amber','a-billing'),listrow('home','Home visit requests','1 request awaiting review','1','blue','a-homevisits'),
  ],{nav:0});


  // Additional current-app workflows identified by the coverage audit.
  const additionalScreens = [
  {
    "id": "auth-onboarding-1",
    "role": "auth",
    "name": "Added · Welcome to MyHealth Care",
    "title": "Welcome to MyHealth Care",
    "source": "lib/features/auth/presentation/onboarding_overlay.dart",
    "back": "auth-login",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Continue",
        "auth-onboarding-2"
      ],
      [
        "Skip",
        "auth-login"
      ]
    ],
    "note": "Keep your appointments and records together."
  },
  {
    "id": "auth-onboarding-2",
    "role": "auth",
    "name": "Added · Your care team",
    "title": "Your care team",
    "source": "lib/features/auth/presentation/onboarding_overlay.dart",
    "back": "auth-login",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Continue",
        "auth-onboarding-3"
      ],
      [
        "Skip",
        "auth-login"
      ]
    ],
    "note": "Find your visits, health information and messages."
  },
  {
    "id": "auth-onboarding-3",
    "role": "auth",
    "name": "Added · Make it comfortable",
    "title": "Make it comfortable",
    "source": "lib/features/auth/presentation/onboarding_overlay.dart",
    "back": "auth-login",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Continue",
        "auth-login"
      ],
      [
        "Skip",
        "auth-login"
      ]
    ],
    "note": "Choose language and appearance before continuing."
  },
  {
    "id": "auth-session",
    "role": "auth",
    "name": "Added · Still there?",
    "title": "Still there?",
    "source": "lib/features/auth/presentation/session_activity_monitor.dart",
    "back": "p-home",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Keep working",
        "p-home"
      ],
      [
        "Sign out",
        "auth-login"
      ]
    ],
    "note": "Your session is about to expire. Confirm to continue your current task."
  },
  {
    "id": "auth-reauth",
    "role": "auth",
    "name": "Added · Confirm your password",
    "title": "Confirm your password",
    "source": "lib/features/auth/presentation/reauth_prompt.dart",
    "back": "p-password",
    "fields": [
      [
        "Current password",
        "Enter your password",
        "lock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm",
        "p-password"
      ]
    ],
    "note": "Confirm your identity before changing account details."
  },
  {
    "id": "p-photo",
    "role": "patient",
    "name": "Added · Profile photo",
    "title": "Profile photo",
    "source": "lib/features/patient/presentation/avatar_photo_sheet.dart",
    "back": "p-profile",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Choose photo",
        "p-profile"
      ],
      [
        "Take a photo",
        "p-profile"
      ],
      [
        "Remove photo",
        "p-profile"
      ]
    ],
    "note": "Stored on this device. Choose an image up to 5 MB. Camera capture appears on supported mobile devices."
  },
  {
    "id": "p-photo-error",
    "role": "patient",
    "name": "Added · Photo could not be saved",
    "title": "Photo could not be saved",
    "source": "lib/features/patient/presentation/avatar_photo_sheet.dart",
    "back": "p-photo",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Choose another photo",
        "p-photo"
      ]
    ],
    "note": "Keep your previous photo. Choose a smaller image or try again."
  },
  {
    "id": "p-password",
    "role": "patient",
    "name": "Added · Change password",
    "title": "Change password",
    "source": "lib/features/patient/application/profile_screen.dart",
    "back": "p-profile",
    "fields": [
      [
        "Current password",
        "Enter current password",
        "lock"
      ],
      [
        "New password",
        "Choose a strong password",
        "lock"
      ],
      [
        "Confirm password",
        "Repeat new password",
        "lock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Change password",
        "p-profile"
      ]
    ],
    "note": "Your current password is required. This is separate from password recovery."
  },
  {
    "id": "p-feedback",
    "role": "patient",
    "name": "Added · Send feedback",
    "title": "Send feedback",
    "source": "lib/features/feedback/presentation/feedback_sheet.dart",
    "back": "p-profile",
    "fields": [
      [
        "Feedback",
        "Tell us what happened",
        "chat"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Send feedback",
        "p-profile"
      ]
    ],
    "note": "Wait for confirmation that your feedback was saved. This is not a care message."
  },
  {
    "id": "p-visited",
    "role": "patient",
    "name": "Added · Visited doctors",
    "title": "Visited doctors",
    "source": "lib/features/patient/presentation/visited_doctors_screen.dart",
    "back": "p-appointments",
    "fields": [],
    "items": [
      [
        "user",
        "Dr. Omar Khalil",
        "Cardiology · Last visit 12 Sep",
        null,
        "blue",
        "p-booking"
      ]
    ],
    "actions": [
      [
        "Book again",
        "p-booking"
      ]
    ],
    "note": null
  },
  {
    "id": "p-imaging",
    "role": "patient",
    "name": "Added · Imaging results",
    "title": "Imaging results",
    "source": "lib/features/records/presentation/radiology_screen.dart",
    "back": "p-records",
    "fields": [],
    "items": [
      [
        "record",
        "Chest X-ray",
        "28 Aug 2026 · Reviewed",
        "Reviewed",
        "green",
        "p-result"
      ]
    ],
    "actions": [
      [
        "Download report",
        "p-imaging"
      ]
    ],
    "note": null
  },
  {
    "id": "p-allergies",
    "role": "patient",
    "name": "Added · Allergies",
    "title": "Allergies",
    "source": "lib/features/patient/presentation/allergies_screen.dart",
    "back": "p-records",
    "fields": [],
    "items": [
      [
        "warning",
        "Penicillin",
        "Recorded in your health details",
        "Recorded",
        "red",
        "p-health"
      ]
    ],
    "actions": [
      [
        "Update health details",
        "p-health"
      ]
    ],
    "note": null
  },
  {
    "id": "p-sickleave",
    "role": "patient",
    "name": "Added · Sick leave certificates",
    "title": "Sick leave certificates",
    "source": "lib/features/care/presentation/sick_leave_screen.dart",
    "back": "p-records",
    "fields": [],
    "items": [
      [
        "record",
        "Sick leave certificate",
        "Issued 14 Aug 2026",
        null,
        "blue",
        "p-sickleave"
      ]
    ],
    "actions": [
      [
        "Download certificate",
        "p-sickleave"
      ]
    ],
    "note": null
  },
  {
    "id": "p-summary",
    "role": "patient",
    "name": "Added · Health summary",
    "title": "Health summary",
    "source": "lib/features/ai_summary/presentation/ai_summary_screen.dart",
    "back": "p-records",
    "fields": [],
    "items": [
      [
        "heart",
        "Recent measurements",
        "Blood pressure, weight and pulse",
        null,
        "blue",
        "p-vitals"
      ],
      [
        "pill",
        "Current medicines",
        "From your saved medication records",
        null,
        "blue",
        "p-medications"
      ]
    ],
    "actions": [],
    "note": "Generated summary for review. Original records remain the source of truth."
  },
  {
    "id": "p-assistant",
    "role": "patient",
    "name": "Added · Care Navigator",
    "title": "Care Navigator",
    "source": "lib/features/ai_chat/presentation/care_navigator_panel.dart",
    "back": "p-home",
    "fields": [
      [
        "Question",
        "Ask about booking or navigating your records",
        "chat"
      ]
    ],
    "items": [],
    "actions": [
      [
        "View appointments",
        "p-appointments"
      ],
      [
        "Open records",
        "p-records"
      ]
    ],
    "note": "For navigation and non-emergency information. Keep your care team informed."
  },
  {
    "id": "p-topup",
    "role": "patient",
    "name": "Added · Top up wallet",
    "title": "Top up wallet",
    "source": "lib/features/billing/presentation/wallet_topup_sheet.dart",
    "back": "p-payments",
    "fields": [
      [
        "Amount",
        "BD 20.00",
        "wallet"
      ],
      [
        "Payment method",
        "Demo card · •••• 4242",
        "wallet"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm top-up",
        "p-payments"
      ]
    ],
    "note": "Demo payment. Wallet funds change only after confirmation; no real money is charged."
  },
  {
    "id": "p-methods",
    "role": "patient",
    "name": "Added · Payment methods",
    "title": "Payment methods",
    "source": "lib/features/billing/presentation/payment_methods_section.dart",
    "back": "p-payments",
    "fields": [],
    "items": [
      [
        "wallet",
        "Demo card · •••• 4242",
        "Expires 12/28",
        "Default",
        "blue",
        "p-card-add"
      ]
    ],
    "actions": [
      [
        "Add card",
        "p-card-add"
      ],
      [
        "Remove card",
        "p-methods"
      ]
    ],
    "note": null
  },
  {
    "id": "p-card-add",
    "role": "patient",
    "name": "Added · Add payment card",
    "title": "Add payment card",
    "source": "lib/features/billing/presentation/payment_methods_section.dart",
    "back": "p-methods",
    "fields": [
      [
        "Card details",
        "Enter demo card details",
        "wallet"
      ],
      [
        "Expiry",
        "MM/YY",
        "calendar"
      ],
      [
        "Security code",
        "CVC",
        "lock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save card",
        "p-methods"
      ]
    ],
    "note": "Only the masked descriptor appears after saving. Follow the app payment mode."
  },
  {
    "id": "p-pay-history",
    "role": "patient",
    "name": "Added · Transaction history",
    "title": "Transaction history",
    "source": "lib/features/billing/presentation/payment_history.dart",
    "back": "p-payments",
    "fields": [],
    "items": [
      [
        "wallet",
        "Invoice payment · BD 20.00",
        "12 Sep 2026",
        "Settled",
        "green",
        "p-payments"
      ],
      [
        "wallet",
        "Wallet top-up · BD 10.00",
        "10 Sep 2026",
        "Settled",
        "green",
        "p-payments"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "p-family-member",
    "role": "patient",
    "name": "Added · Family member",
    "title": "Family member",
    "source": "lib/features/patient/presentation/family_network_section.dart",
    "back": "p-family",
    "fields": [
      [
        "Relationship",
        "Child",
        "users"
      ],
      [
        "First name",
        "Layla",
        "user"
      ],
      [
        "Last name",
        "Ahmed",
        "user"
      ],
      [
        "Date of birth",
        "Optional",
        "calendar"
      ],
      [
        "Phone",
        "Optional",
        "user"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save family member",
        "p-family"
      ]
    ],
    "note": "A family member record does not automatically grant access to another signed-in account."
  },
  {
    "id": "p-family-request",
    "role": "patient",
    "name": "Added · Request account access",
    "title": "Request account access",
    "source": "lib/features/patient/presentation/linked_family_accounts_section.dart",
    "back": "p-family",
    "fields": [
      [
        "Find account",
        "Search for a family member",
        "search"
      ],
      [
        "Requested access",
        "View only or manage",
        "lock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Send request",
        "p-family"
      ]
    ],
    "note": "The account owner must consent before you can view or manage their information."
  },
  {
    "id": "p-family-consent",
    "role": "patient",
    "name": "Added · Review access request",
    "title": "Review access request",
    "source": "lib/features/patient/presentation/linked_family_accounts_section.dart",
    "back": "p-family",
    "fields": [],
    "items": [
      [
        "user",
        "Mariam Ali",
        "Requests view-only access",
        "Pending",
        "amber",
        "p-family"
      ]
    ],
    "actions": [
      [
        "Accept request",
        "p-family"
      ],
      [
        "Decline request",
        "p-family"
      ]
    ],
    "note": "Review the requested permission before granting access to your account."
  },
  {
    "id": "p-family-revoke",
    "role": "patient",
    "name": "Added · Who has access to me",
    "title": "Who has access to me",
    "source": "lib/features/patient/presentation/linked_family_accounts_section.dart",
    "back": "p-family",
    "fields": [],
    "items": [
      [
        "user",
        "Mariam Ali",
        "View-only access",
        "Granted",
        "blue",
        "p-family-revoke"
      ]
    ],
    "actions": [
      [
        "Revoke access",
        "p-family"
      ]
    ],
    "note": "Revoking access removes the linked account permission. Confirm before continuing."
  },
  {
    "id": "p-linked-manage",
    "role": "patient",
    "name": "Added · Manage linked account",
    "title": "Manage linked account",
    "source": "lib/features/patient/presentation/linked_account_screen.dart",
    "back": "p-family",
    "fields": [],
    "items": [
      [
        "calendar",
        "Layla Ahmed · Next visit",
        "8 Oct 2026",
        "Confirmed",
        "green",
        "p-ticket"
      ]
    ],
    "actions": [
      [
        "Book for Layla",
        "p-booking"
      ],
      [
        "View health information",
        "p-records"
      ]
    ],
    "note": "Acting for Layla Ahmed · manage access. The app rechecks your grant before every action."
  },
  {
    "id": "p-reschedule",
    "role": "patient",
    "name": "Added · Reschedule appointment",
    "title": "Reschedule appointment",
    "source": "lib/features/appointments/presentation/slot_picker_sheet.dart",
    "back": "p-ticket",
    "fields": [
      [
        "Date",
        "Choose an available date",
        "calendar"
      ],
      [
        "Time",
        "Select a free slot",
        "clock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm new time",
        "p-ticket"
      ]
    ],
    "note": "The original visit remains booked until the new time is confirmed."
  },
  {
    "id": "p-no-slots",
    "role": "patient",
    "name": "Added · No available times",
    "title": "No available times",
    "source": "lib/features/booking/presentation/booking_screen.dart",
    "back": "p-slot",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Choose another day",
        "p-slot"
      ],
      [
        "Choose another clinician",
        "p-booking"
      ]
    ],
    "note": "No slots are available for the selected date and clinician."
  },
  {
    "id": "p-booking-conflict",
    "role": "patient",
    "name": "Added · That time is no longer available",
    "title": "That time is no longer available",
    "source": "lib/features/booking/presentation/booking_screen.dart",
    "back": "p-slot",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Refresh available times",
        "p-slot"
      ]
    ],
    "note": "Your selection could not be confirmed. Choose another slot; your other booking details remain available."
  },
  {
    "id": "p-homevisits-history",
    "role": "patient",
    "name": "Added · Home care requests",
    "title": "Home care requests",
    "source": "lib/features/care/presentation/home_visit_screen.dart",
    "back": "p-home",
    "fields": [],
    "items": [
      [
        "home",
        "Home visit request",
        "Requested 1 Oct 2026",
        "Pending",
        "amber",
        "p-homevisits-history"
      ]
    ],
    "actions": [
      [
        "New request",
        "p-homevisit"
      ]
    ],
    "note": "A request is not a confirmed visit. The clinic reviews each request before arranging care."
  },
  {
    "id": "p-notifications",
    "role": "patient",
    "name": "Added · Notifications",
    "title": "Notifications",
    "source": "lib/features/notifications/presentation/notifications_screen.dart",
    "back": "p-home",
    "fields": [],
    "items": [
      [
        "bell",
        "Appointment update",
        "Today · Unread",
        "New",
        "blue",
        "p-ticket"
      ]
    ],
    "actions": [
      [
        "Mark all read",
        "p-notifications"
      ]
    ],
    "note": null
  },
  {
    "id": "p-reset-prefs",
    "role": "patient",
    "name": "Added · Reset preferences",
    "title": "Reset preferences",
    "source": "lib/features/settings/presentation/preferences_section.dart",
    "back": "p-preferences",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Confirm reset",
        "p-preferences"
      ],
      [
        "Keep current choices",
        "p-preferences"
      ]
    ],
    "note": "Appearance and notification groups have separate resets. Confirm which group you are resetting."
  },
  {
    "id": "s-notifications",
    "role": "staff",
    "name": "Added · Notifications",
    "title": "Notifications",
    "source": "lib/features/notifications/presentation/notifications_screen.dart",
    "back": "s-home",
    "fields": [],
    "items": [
      [
        "bell",
        "Appointment update",
        "Today · Unread",
        "New",
        "blue",
        "s-schedule"
      ]
    ],
    "actions": [
      [
        "Mark all read",
        "s-notifications"
      ]
    ],
    "note": null
  },
  {
    "id": "s-reset-prefs",
    "role": "staff",
    "name": "Added · Reset preferences",
    "title": "Reset preferences",
    "source": "lib/features/settings/presentation/preferences_section.dart",
    "back": "s-preferences",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Confirm reset",
        "s-preferences"
      ],
      [
        "Keep current choices",
        "s-preferences"
      ]
    ],
    "note": "Appearance and notification groups have separate resets. Confirm which group you are resetting."
  },
  {
    "id": "a-notifications",
    "role": "admin",
    "name": "Added · Notifications",
    "title": "Notifications",
    "source": "lib/features/notifications/presentation/notifications_screen.dart",
    "back": "a-home",
    "fields": [],
    "items": [
      [
        "bell",
        "Appointment update",
        "Today · Unread",
        "New",
        "blue",
        "a-appointments"
      ]
    ],
    "actions": [
      [
        "Mark all read",
        "a-notifications"
      ]
    ],
    "note": null
  },
  {
    "id": "a-reset-prefs",
    "role": "admin",
    "name": "Added · Reset preferences",
    "title": "Reset preferences",
    "source": "lib/features/settings/presentation/preferences_section.dart",
    "back": "a-preferences",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Confirm reset",
        "a-preferences"
      ],
      [
        "Keep current choices",
        "a-preferences"
      ]
    ],
    "note": "Appearance and notification groups have separate resets. Confirm which group you are resetting."
  },
  {
    "id": "s-account",
    "role": "staff",
    "name": "Added · Staff account",
    "title": "Staff account",
    "source": "lib/features/staff_dashboard/presentation/staff_profile_pages.dart",
    "back": "s-profile",
    "fields": [],
    "items": [
      [
        "user",
        "Dr. Omar Khalil",
        "Doctor · Cardiology",
        null,
        "blue",
        "s-account"
      ],
      [
        "record",
        "License details",
        "Maintained by the administrator",
        null,
        "blue",
        "s-account"
      ]
    ],
    "actions": [],
    "note": "Account details are read-only. Contact the administrator to update them."
  },
  {
    "id": "s-activity",
    "role": "staff",
    "name": "Added · My activity",
    "title": "My activity",
    "source": "lib/features/staff_dashboard/presentation/staff_activity_screen.dart",
    "back": "s-profile",
    "fields": [],
    "items": [
      [
        "record",
        "Clinical note saved",
        "Sara Ahmed · Today",
        null,
        "blue",
        "s-chart"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "s-directory",
    "role": "staff",
    "name": "Added · Staff directory",
    "title": "Staff directory",
    "source": "lib/features/staff_dashboard/presentation/staff_directory_screen.dart",
    "back": "s-profile",
    "fields": [
      [
        "Search",
        "Name, specialty or department",
        "search"
      ]
    ],
    "items": [
      [
        "user",
        "Dr. Lina Haddad",
        "Dermatology",
        "Off shift",
        "amber",
        "s-directory"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "s-analytics",
    "role": "staff",
    "name": "Added · Panel analytics",
    "title": "Panel analytics",
    "source": "lib/features/staff_dashboard/presentation/panel_analytics_screen.dart",
    "back": "s-profile",
    "fields": [],
    "items": [],
    "actions": [],
    "note": "Metrics describe your permitted patient panel. Missing data is shown as unavailable, not zero."
  },
  {
    "id": "s-tools",
    "role": "staff",
    "name": "Added · Clinical actions",
    "title": "Clinical actions",
    "source": "lib/features/staff_dashboard/presentation/staff_quick_actions.dart",
    "back": "s-home",
    "fields": [],
    "items": [
      [
        "record",
        "New note",
        "Choose a patient",
        null,
        "blue",
        "s-note"
      ],
      [
        "pill",
        "Prescribe",
        "Choose a patient",
        null,
        "blue",
        "s-prescribe"
      ],
      [
        "lab",
        "Enter lab result",
        "Choose a patient",
        null,
        "blue",
        "s-lab-entry"
      ],
      [
        "calendar",
        "Transfer visit",
        "Choose a visit",
        null,
        "blue",
        "s-transfer"
      ],
      [
        "record",
        "AI scribe",
        "Human-reviewed draft",
        null,
        "blue",
        "s-scribe"
      ],
      [
        "record",
        "Patient summary",
        "Open source records",
        null,
        "blue",
        "s-summary"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "s-summary",
    "role": "staff",
    "name": "Added · Patient summary",
    "title": "Patient summary",
    "source": "lib/features/patient_chart/presentation/patient_summary_screen.dart",
    "back": "s-chart",
    "fields": [],
    "items": [],
    "actions": [],
    "note": "Sara Ahmed · Summary of permitted records. Check the source chart before acting."
  },
  {
    "id": "s-scribe",
    "role": "staff",
    "name": "Added · Clinical scribe",
    "title": "Clinical scribe",
    "source": "lib/features/ai_scribe/presentation/clinical_scribe_screen.dart",
    "back": "s-chart",
    "fields": [
      [
        "Visit notes",
        "Enter the consultation context",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Generate draft",
        "s-scribe"
      ],
      [
        "Review draft",
        "s-consultation"
      ]
    ],
    "note": "AI output is a draft for clinician review. Core chart actions remain available when AI is unavailable."
  },
  {
    "id": "s-note",
    "role": "staff",
    "name": "Added · New clinical note",
    "title": "New clinical note",
    "source": "lib/features/patient_chart/presentation/chart_write_sheets.dart",
    "back": "s-chart",
    "fields": [
      [
        "Clinical note",
        "Record assessment and plan",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save to chart",
        "s-chart"
      ]
    ],
    "note": "Sara Ahmed · Available actions depend on your clinical role and access. Saving requires confirmation."
  },
  {
    "id": "s-prescribe",
    "role": "staff",
    "name": "Added · Medication order",
    "title": "Medication order",
    "source": "lib/features/patient_chart/presentation/chart_write_sheets.dart",
    "back": "s-chart",
    "fields": [
      [
        "Medicine",
        "Choose a medicine",
        "pill"
      ],
      [
        "Dose",
        "Dose and unit",
        "record"
      ],
      [
        "Frequency",
        "Instructions",
        "clock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save to chart",
        "s-chart"
      ]
    ],
    "note": "Sara Ahmed · Available actions depend on your clinical role and access. Saving requires confirmation."
  },
  {
    "id": "s-lab-entry",
    "role": "staff",
    "name": "Added · Enter lab result",
    "title": "Enter lab result",
    "source": "lib/features/patient_chart/presentation/chart_write_sheets.dart",
    "back": "s-chart",
    "fields": [
      [
        "Analyte",
        "Result name",
        "lab"
      ],
      [
        "Value and unit",
        "Enter the measured value",
        "record"
      ],
      [
        "Reference range",
        "From the source report",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save to chart",
        "s-chart"
      ]
    ],
    "note": "Sara Ahmed · Available actions depend on your clinical role and access. Saving requires confirmation."
  },
  {
    "id": "s-transfer",
    "role": "staff",
    "name": "Added · Transfer visit",
    "title": "Transfer visit",
    "source": "lib/features/staff_dashboard/presentation/staff_quick_actions.dart",
    "back": "s-schedule",
    "fields": [
      [
        "Appointment",
        "Select the patient visit",
        "calendar"
      ],
      [
        "Receiving clinician",
        "Select an available clinician",
        "user"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm transfer",
        "s-schedule"
      ]
    ],
    "note": "Review the patient, receiving clinician and available time before transferring."
  },
  {
    "id": "s-calendar-month",
    "role": "staff",
    "name": "Added · Month schedule",
    "title": "Month schedule",
    "source": "lib/features/staff_dashboard/presentation/staff_schedule_screen.dart",
    "back": "s-schedule",
    "fields": [],
    "items": [
      [
        "calendar",
        "October 2026",
        "Select a day to see the agenda",
        null,
        "blue",
        "s-schedule"
      ]
    ],
    "actions": [
      [
        "Today",
        "s-schedule"
      ],
      [
        "Year view",
        "s-calendar-year"
      ]
    ],
    "note": null
  },
  {
    "id": "s-calendar-year",
    "role": "staff",
    "name": "Added · Year schedule",
    "title": "Year schedule",
    "source": "lib/features/staff_dashboard/presentation/staff_schedule_screen.dart",
    "back": "s-calendar-month",
    "fields": [],
    "items": [
      [
        "calendar",
        "January 2026",
        "Open month",
        null,
        "blue",
        "s-calendar-month"
      ],
      [
        "calendar",
        "April 2026",
        "Open month",
        null,
        "blue",
        "s-calendar-month"
      ],
      [
        "calendar",
        "July 2026",
        "Open month",
        null,
        "blue",
        "s-calendar-month"
      ],
      [
        "calendar",
        "October 2026",
        "Open month",
        null,
        "blue",
        "s-calendar-month"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "s-feedback",
    "role": "staff",
    "name": "Added · Send feedback",
    "title": "Send feedback",
    "source": "lib/features/feedback/presentation/feedback_sheet.dart",
    "back": "s-profile",
    "fields": [
      [
        "Feedback",
        "Tell us what happened",
        "chat"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Send feedback",
        "s-profile"
      ]
    ],
    "note": null
  },
  {
    "id": "s-access-denied",
    "role": "staff",
    "name": "Added · Patient access unavailable",
    "title": "Patient access unavailable",
    "source": "lib/features/patient_chart/presentation/patient_chart_screen.dart",
    "back": "s-patients",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Return to patients",
        "s-patients"
      ]
    ],
    "note": "Your current role or assignment does not allow this patient record. Refresh the list or contact the administrator."
  },
  {
    "id": "s-conflict",
    "role": "staff",
    "name": "Added · The chart changed",
    "title": "The chart changed",
    "source": "lib/features/consultation/presentation/consultation_screen.dart",
    "back": "s-consultation",
    "fields": [],
    "items": [],
    "actions": [
      [
        "Reload latest version",
        "s-consultation"
      ],
      [
        "Keep reviewing",
        "s-consultation"
      ]
    ],
    "note": "Keep your draft visible. Review the latest saved version before trying to save again."
  },
  {
    "id": "a-account",
    "role": "admin",
    "name": "Added · Administrator account",
    "title": "Administrator account",
    "source": "lib/features/admin/presentation/admin_profile_pages.dart",
    "back": "a-profile",
    "fields": [],
    "items": [
      [
        "user",
        "Administrator",
        "admin@myhealth.demo",
        null,
        "blue",
        "a-account"
      ]
    ],
    "actions": [],
    "note": "Account identity is separate from clinic configuration and personal preferences."
  },
  {
    "id": "a-forecast",
    "role": "admin",
    "name": "Added · Capacity forecast",
    "title": "Capacity forecast",
    "source": "lib/features/admin/presentation/admin_forecast_screen.dart",
    "back": "a-profile",
    "fields": [],
    "items": [],
    "actions": [],
    "note": "Review appointment demand, staffing and the forecast source and period. Do not treat a missing forecast as zero demand."
  },
  {
    "id": "a-ai-log",
    "role": "admin",
    "name": "Added · AI activity",
    "title": "AI activity",
    "source": "lib/features/admin/presentation/admin_ai_log_screen.dart",
    "back": "a-profile",
    "fields": [
      [
        "Search activity",
        "Patient, model or action",
        "search"
      ]
    ],
    "items": [
      [
        "record",
        "Clinical summary generated",
        "Demo / offline · Today",
        null,
        "blue",
        "a-ai-log"
      ]
    ],
    "actions": [],
    "note": "AI activity is separate from the general audit log."
  },
  {
    "id": "a-appointments",
    "role": "admin",
    "name": "Added · All appointments",
    "title": "All appointments",
    "source": "lib/features/admin/presentation/admin_appointments_screen.dart",
    "back": "a-home",
    "fields": [
      [
        "Search appointments",
        "Patient or clinician",
        "search"
      ]
    ],
    "items": [
      [
        "calendar",
        "Sara Ahmed · Dr. Omar Khalil",
        "3 Oct 2026 · 10:30 AM",
        "Confirmed",
        "green",
        "a-book-patient"
      ]
    ],
    "actions": [],
    "note": null
  },
  {
    "id": "a-feedback",
    "role": "admin",
    "name": "Added · Feedback queue",
    "title": "Feedback queue",
    "source": "lib/features/admin/presentation/admin_feedback_screen.dart",
    "back": "a-home",
    "fields": [],
    "items": [
      [
        "chat",
        "Profile feedback",
        "Received today",
        "Open",
        "amber",
        "a-feedback"
      ]
    ],
    "actions": [
      [
        "Resolve feedback",
        "a-feedback"
      ],
      [
        "Reopen feedback",
        "a-feedback"
      ]
    ],
    "note": null
  },
  {
    "id": "a-create-patient",
    "role": "admin",
    "name": "Added · Create patient account",
    "title": "Create patient account",
    "source": "lib/features/admin/presentation/user_management_screen.dart",
    "back": "a-users",
    "fields": [
      [
        "Full name",
        "Enter patient name",
        "user"
      ],
      [
        "Email",
        "name@example.com",
        "mail"
      ],
      [
        "Temporary password",
        "Enter temporary password",
        "lock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Create patient",
        "a-users"
      ]
    ],
    "note": null
  },
  {
    "id": "a-broadcast",
    "role": "admin",
    "name": "Added · Send announcement",
    "title": "Send announcement",
    "source": "lib/features/admin/presentation/admin_quick_actions.dart",
    "back": "a-home",
    "fields": [
      [
        "Audience",
        "Choose account roles",
        "users"
      ],
      [
        "Title",
        "Announcement title",
        "record"
      ],
      [
        "Message",
        "Write the announcement",
        "chat"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Send announcement",
        "a-home"
      ]
    ],
    "note": "Confirm audience and delivery availability before sending. Unavailable channels are not shown as delivered."
  },
  {
    "id": "a-create-invoice",
    "role": "admin",
    "name": "Added · Create invoice",
    "title": "Create invoice",
    "source": "lib/features/admin/presentation/admin_quick_actions.dart",
    "back": "a-billing",
    "fields": [
      [
        "Patient",
        "Choose a patient",
        "user"
      ],
      [
        "Subtotal",
        "BD 35.00",
        "wallet"
      ],
      [
        "Tax",
        "Tax rate",
        "record"
      ],
      [
        "Notes",
        "Optional description",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Create invoice",
        "a-billing"
      ]
    ],
    "note": null
  },
  {
    "id": "a-staff-schedule",
    "role": "admin",
    "name": "Added · Clinician schedule",
    "title": "Clinician schedule",
    "source": "lib/features/admin/presentation/user_management_screen.dart",
    "back": "a-user",
    "fields": [
      [
        "Day",
        "Choose a weekday",
        "calendar"
      ],
      [
        "Start",
        "08:00",
        "clock"
      ],
      [
        "End",
        "16:00",
        "clock"
      ],
      [
        "Slot duration",
        "Minutes",
        "clock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save schedule",
        "a-user"
      ]
    ],
    "note": "Schedule templates are separate from clinic-wide opening hours. Validate time and existing appointments."
  },
  {
    "id": "a-book-patient",
    "role": "admin",
    "name": "Added · Book for patient",
    "title": "Book for patient",
    "source": "lib/features/admin/presentation/user_management_screen.dart",
    "back": "a-users",
    "fields": [
      [
        "Patient",
        "Sara Ahmed",
        "user"
      ],
      [
        "Department",
        "Choose a department",
        "building"
      ],
      [
        "Clinician",
        "Choose a clinician",
        "user"
      ],
      [
        "Time",
        "Select an available time",
        "clock"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm appointment",
        "a-appointments"
      ]
    ],
    "note": null
  },
  {
    "id": "a-refer-patient",
    "role": "admin",
    "name": "Added · Refer patient",
    "title": "Refer patient",
    "source": "lib/features/admin/presentation/user_management_screen.dart",
    "back": "a-users",
    "fields": [
      [
        "Patient",
        "Sara Ahmed",
        "user"
      ],
      [
        "Destination",
        "Choose department",
        "building"
      ],
      [
        "Referral note",
        "Record the clinical context",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Save referral",
        "a-referrals"
      ]
    ],
    "note": null
  },
  {
    "id": "a-refund",
    "role": "admin",
    "name": "Added · Refund settled payment",
    "title": "Refund settled payment",
    "source": "lib/features/admin/presentation/admin_billing_screen.dart",
    "back": "a-invoice",
    "fields": [
      [
        "Refund amount",
        "BD 20.00",
        "wallet"
      ],
      [
        "Reason",
        "Explain the refund",
        "record"
      ]
    ],
    "items": [],
    "actions": [
      [
        "Confirm refund",
        "a-invoice"
      ]
    ],
    "note": "Refund only a settled charge, up to the remaining refundable amount. Wait for the recorded result."
  },
  {
    "id": "a-reconcile",
    "role": "admin",
    "name": "Added · Check pending payments",
    "title": "Check pending payments",
    "source": "lib/features/admin/presentation/admin_billing_screen.dart",
    "back": "a-billing",
    "fields": [],
    "items": [
      [
        "wallet",
        "INV-1042 · Sara Ahmed",
        "BD 35.00",
        "Pending",
        "amber",
        "a-invoice"
      ]
    ],
    "actions": [
      [
        "Check provider status",
        "a-billing"
      ]
    ],
    "note": "An invoice is paid only after confirmation. Checking status does not create another charge."
  }
];
  additionalScreens.forEach(e => screen(e.id,e.role,e.name,e.title,[
    ...(e.note?[note(e.note,'record','blue')]:[]),
    ...e.fields.map(f=>field(...f)),
    ...e.items.map(item=>listrow(...item)),
    ...e.actions.map((a,i)=>button(a[0],a[1],i===0?'primary':'secondary')),
  ],{back:e.back}));

  // Desktop designs use the same component vocabulary and task ordering.
  function desktop(id,role,name,main) {
    const sidebar=col([row([F('Mark',[I('heart','white',24)],{width:38,height:38,bg:'primary',radius:12,align:'center',justify:'center'}),T('MyHealth Care',18,600)]),T(role==='patient'?'YOUR HEALTH':role==='staff'?'CLINICAL WORKSPACE':'ADMINISTRATION',10,600,'muted',{tracking:1.4}),...navs[role].map(([icon,label,target],i)=>({...row([I(icon,i===0?'primary':'muted'),T(label,14,600,i===0?'primary':'muted',{grow:1})],{padding:14,bg:i===0?'header':null,radius:12}),target})),F('Space',[],{grow:1}),note('Synthetic demo data','lock','blue'),row([I('settings','muted'),T('Preferences',13,500,'muted',{target:role==='patient'?'p-preferences':role==='staff'?'s-preferences':'a-preferences'})])],{width:248,height:960,padding:24,bg:'surface',gap:20});
    screens.push({id,role,name,width:1440,desktop:true,tree:row([sidebar,col([row([col([T('Friday, 2 October 2026',12,500,'muted'),T(role==='patient'?'Good morning, Sara':role==='staff'?'Your shift, at a glance':'Work needing your attention',28,600,'ink',{family:'Lexend'})],{grow:1}),F('Notifications',[I('bell')],{width:44,height:44,bg:'surface',radius:22,align:'center',justify:'center'})]),...main],{grow:1,padding:32,gap:24})],{width:1440,minHeight:960,bg:'page',gap:0,align:'stretch',radius:20})});
  }
  desktop('p-desktop','patient','31 · Desktop / patient overview',[
    note('Allergy recorded: penicillin · 1 new reply from your care team','warning','amber'),
    row([col([hero('Next appointment','Dr. Omar Khalil','Cardiology · Tomorrow, 10:30 AM · Room 204',[['View appointment ticket','p-ticket'],['Reschedule','p-reschedule']]),h('Your health'),metrics([['Blood pressure','118/76','mmHg · 1 Oct'],['Heart rate','72','bpm · 1 Oct'],['Medicines','2','active orders']]),h('Latest records','View all','p-records'),listrow('lab','Routine blood panel','12 Sep 2026 · Lab','Reviewed','green','p-result'),listrow('record','Cardiology consultation','14 Aug 2026 · Dr. Omar Khalil','Reviewed','green','p-result')],{grow:2,gap:18}),col([h('Quick actions'),button('Book an appointment','p-booking'),menu([['chat','Message your doctor','p-messages'],['home','Request home care','p-homevisit'],['pill','Medications','p-medications'],['heart','Vital signs','p-vitals']]),h('Payments'),card([T('1 invoice awaiting payment',14,600),T('BD 35.00',26,600,'primary'),button('View invoice','p-payments','secondary')])],{grow:1,gap:18})],{align:'start',gap:24}),
  ]);
  desktop('s-desktop','staff','14 · Desktop / staff workspace',[
    row([badge('On duty'),T('Cardiology · 6 patients in queue',14,500,'muted',{grow:1}),button('Open schedule','s-schedule','secondary')]),
    row([col([hero('Next patient','Sara Ahmed · 10:30 AM','Checked in · Room 204 · Follow-up',[['Start visit','s-consultation'],['Open chart','s-chart']]),h('Today’s queue'),listrow('user','Sara Ahmed','10:30 AM · Follow-up','Arrived','blue','s-consultation'),listrow('user','Mona Adel','11:15 AM · Consultation','Booked','blue','s-chart'),listrow('user','Ahmed Saleh','1:00 PM · Lab review','Booked','blue','s-result'),h('Frequent actions'),row([button('Find patient','s-patients','secondary'),button('Open care inbox','s-inbox','secondary')],{gap:12})],{grow:1,gap:18}),col([h('Needs attention'),card([row([I('lab'),T('Ahmed Saleh',17,600,'ink',{grow:1}),badge('Overdue','red')]),T('Abnormal result · HbA1c · Owner: you',13,400,'muted'),button('Review result','s-result')]),card([row([I('chat'),T('Mona Adel',17,600,'ink',{grow:1}),badge('Reply due','amber')]),T('Covering Dr. Lina Haddad',13,400,'muted'),button('Open message','s-thread','secondary')]),h('Tasks due','Task board','s-tasks'),listrow('record','Complete unsigned note','Sara Ahmed · Follow-up','Today','amber','s-consultation')],{grow:1,gap:18})],{align:'start',gap:24}),
  ]);
  desktop('a-desktop','admin','22 · Desktop / admin work queue',[
    metrics([['Results without an owner','2'],['Payments to confirm','3'],['Referral requests','2'],['Home visit requests','1']]),
    row([col([h('Exception queue'),search('Search patient, owner or work item'),chips(['All work','Results','Messages','Delivery']),card([
      row([T('PATIENT / WORK',11,600,'muted',{grow:2}),T('OWNER',11,600,'muted',{grow:1}),T('AGE',11,600,'muted',{width:65}),T('STATUS',11,600,'muted',{width:110})]),divider(),
      row([col([T('Ahmed Saleh',14,600),T('Abnormal lab · HbA1c',12,400,'muted')],{grow:2}),T('Unassigned',12,600,'redText',{grow:1}),T('2h',12,500,'muted',{width:65}),badge('Overdue','red')]),divider(),
      row([col([T('Mona Adel',14,600),T('Care message',12,400,'muted')],{grow:2}),T('Dr. Lina',12,500,'muted',{grow:1}),T('1 day',12,500,'muted',{width:65}),badge('Reply due','amber')]),divider(),
      row([col([T('Sara Ahmed',14,600),T('Payment · INV-1042',12,400,'muted')],{grow:2}),T('Admin',12,500,'muted',{grow:1}),T('35m',12,500,'muted',{width:65}),badge('Pending','blue')]),
    ],{padding:20,gap:18}),T('Last checked 10:45 AM · Showing 3 of 8 items',12,400,'muted')],{grow:2,gap:18}),col([h('Selected item'),card([row([I('lab'),badge('Overdue','red')]),T('Ahmed Saleh',22,600),T('Abnormal result review',14,500,'muted'),divider(),T('Owner · Unassigned',14,600,'redText'),T('Waiting since · 8:45 AM',13,400,'muted'),field('Assign to','Dr. Omar Khalil','user'),field('Handover note','Add relevant context','record'),button('Assign review','a-work')],{padding:20,gap:18})],{grow:1,gap:18})],{align:'start',gap:24}),
  ]);
  // Correct accidental argument objects and normalize repeated fields to fill rows.
  function normalize(n,parent) {
    if(n.kind==='text' && typeof n.style.color==='object') {Object.assign(n.style,n.style.color);n.style.color='ink';}
    if(parent?.style?.direction==='row' && n.kind==='frame' && !n.style.width) n.style.grow=n.style.grow||1;
    if(n.children) n.children.forEach(child=>normalize(child,n));
  }
  screens.forEach(s=>normalize(s.tree));
  // Text actions carry navigation on the node, alongside styling.
  function promoteTargets(n){if(n.style?.target){n.target=n.style.target;delete n.style.target;}(n.children||[]).forEach(promoteTargets)}
  screens.forEach(s=>promoteTargets(s.tree));
  root.MyHealthDesign={name:'MyHealth Care — Complete UI Review',colors,icons,screens,roles:['auth','patient','staff','admin']};
  if(typeof module!=='undefined')module.exports=root.MyHealthDesign;
})(typeof globalThis!=='undefined'?globalThis:this);
