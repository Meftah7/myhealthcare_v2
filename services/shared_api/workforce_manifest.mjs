import {readFileSync} from 'node:fs';

export const workforceConfiguration = JSON.parse(readFileSync(new URL('../../assets/demo/workforce.json', import.meta.url), 'utf8'));
export function demoRoster() {
  return workforceConfiguration.groups.flatMap(group => {
    if (!Number.isInteger(group.count) || group.count < 1 || group.count > group.names.length) throw Error('Each configured roster account needs a unique synthetic name.');
    return Array.from({length:group.count}, (_,index) => {
      const n=index+1, suffix=group.idWidth ? String(n).padStart(group.idWidth,'0') : n===1 ? '' : String(n);
      const login=n===1 ? group.firstLocalLogin??group.emailPrefix : group.emailPrefix+n;
      const shared=n===1 ? group.firstSharedLogin??group.emailPrefix : (group.role==='doctor'?'doctor':group.emailPrefix)+n;
      return {id:group.idPrefix+suffix,role:group.role,name:group.names[index],email:login+'@myhealth.demo',sharedEmail:shared+'@shared.demo',departmentId:group.departmentId,departmentName:group.departmentName};
    });
  });
}
