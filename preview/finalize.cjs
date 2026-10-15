const fs=require('fs');
const p=__dirname+'/build-preview.cjs';
let s=fs.readFileSync(p,'utf8');
s=s.replace('.report{max-width:1100px}', '.report{max-width:1100px;overflow-wrap:anywhere}')
 .replace('All accounts · 4 active / inactive fixture','All accounts · 3 active / 1 inactive')
 .replace("+metrics([['Appointments','Today", "+'<h2 style=\"margin-bottom:12px\">Quick Statistics</h2>'+metrics([['Appointments','Today")
 .replace("appointments.filter(a=>a.staff==='Dr Ali Mansoor').map(a=>", "appointments.filter(a=>role==='Doctor'?a.staff==='Dr Ali Mansoor':role==='Dentist'?a.staff==='Dr Sara Abbas':false).map(a=>");
fs.writeFileSync(p,s);
