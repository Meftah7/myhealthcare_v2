import { createServer } from 'node:http';
import { ApiError, digest, fields, id, passwordMatches, requireThat, text, token } from './store.mjs';
import { REPORT_INSTRUCTIONS, answerReportQuestion, clipReport } from './ai.mjs';
import { workspaceOps } from './workspace_ops.mjs';
import { workforceOps } from './workforce_ops.mjs';
import { dutyOps } from './duty_ops.mjs';
import { demoRoster } from './workforce_manifest.mjs';
import { clinicOps } from './clinic_ops.mjs';
import { clinicalOps } from './clinical_ops.mjs';

const idle = 24 * 60 * 1000, lifetime = 12 * 60 * 60 * 1000;
const statuses = ['open', 'inProgress', 'waiting', 'blocked', 'done', 'dismissed'];
const kinds = ['resultReview', 'unsignedNote', 'referralFollowUp', 'documentApproval', 'followUpDue', 'overdueReply', 'riskReview'];
const requiredContent = { sickLeaveCertificate: ['startDate', 'endDate'], attendanceCertificate: ['attendanceDate'],
  visitSummary: ['summary'], fitnessCertificate: ['assessment', 'assessmentDate'] };
function date(value) {
  requireThat(typeof value === 'string' && Number.isFinite(Date.parse(value)));
  if (/^\d{4}-\d{2}-\d{2}$/.test(value)) requireThat(new Date(value).toISOString().slice(0,10) === value);
  return Date.parse(value);
}
function version(row, value) { requireThat(Number.isInteger(value) && row.version === value, 409, 'Changed by another user. Reload before saving.'); }
function admin(actor) { requireThat(actor.role === 'admin', 403, 'Administrator access required.'); }
function fresh(store, actor) { requireThat(store.now() - actor.session.reauthed <= 15 * 60 * 1000, 403, 'Confirm your password first.'); }

export function createApi({ store, origins = [], renderDocument, aiProvider, reportExplainer, reportChat, now = store.now }) {
  const buckets = new Map();
  function limit(key, maximum) {
    const time = now(), item = buckets.get(key);
    const next = !item || time - item.at >= 60000 ? { at: time, count: 1 } : { ...item, count: item.count + 1 };
    if (buckets.size > 10000) for (const [k, v] of buckets) if (time - v.at >= 60000) buckets.delete(k);
    buckets.set(key, next); requireThat(next.count <= maximum, 429, 'Too many requests. Try again later.');
  }
  function actorFor(req) {
    const raw = req.headers.authorization;
    requireThat(typeof raw === 'string' && /^Bearer [A-Za-z0-9_-]{43}$/.test(raw), 401, 'Sign in again.');
    const session = store.get('SELECT * FROM sessions WHERE hash=?', digest(raw.slice(7)));
    requireThat(session && now() - session.created < lifetime && now() - session.touched < idle, 401, 'Sign in again.');
    const user = store.get('SELECT * FROM users WHERE id=?', session.user_id);
    requireThat(user?.active && user.auth_version === session.auth_version, 401, 'Sign in again.');
    return { ...user, session };
  }
  function taskAccess(actor, taskId) {
    const task = store.get('SELECT * FROM tasks WHERE id=?', taskId);
    requireThat(task, 404, 'Task unavailable.');
    requireThat(actor.role === 'staff' && (actor.id === task.owner || actor.id===task.coverage_staff&&task.coverage_until>now()), 403, 'Task access denied.');
    store.patientAccess(actor, task.patient); return task;
  }
  function documentAccess(actor, docId) {
    const document = store.get('SELECT * FROM documents WHERE id=?', docId);
    requireThat(document, 404, 'Document unavailable.');
    // Admins see operational metadata, not clinical content or reprint bytes.
    store.patientAccess(actor, document.patient); return document;
  }
  function requestAccess(actor, requestId) {
    const request = store.get('SELECT * FROM requests WHERE id=?', requestId);
    requireThat(request, 404, 'Request unavailable.');
    requireThat(actor.role === 'staff', 403, 'Staff access required.');
    store.patientAccess(actor, request.patient); return request;
  }
  function signer(actor, template) {
    fresh(store,actor);
    requireThat(template.approved === 1, 403, 'Clinic policy approval required.');
    requireThat(actor.role === 'staff' && ['doctor','dentist'].includes(actor.job) && actor.credential_until > now(),
      403, 'A doctor or dentist with a current verified qualification must sign.');
  }
  function validateContent(template, content) {
    const required = requiredContent[template.type];
    requireThat(required, 400, 'This document type has no shared issuance adapter yet.');
    fields(content, required);
    for (const field of required) text(content[field], field.includes('Date') ? 10 : 4000);
    for (const field of required.filter(f => f.includes('Date'))) {
      requireThat(/^\d{4}-\d{2}-\d{2}$/.test(content[field])); date(content[field]);
    }
    if (template.type === 'sickLeaveCertificate') requireThat(content.startDate <= content.endDate, 400, 'Invalid leave dates.');
    requireThat(template.disclosure === 'clinic' || ['sickLeaveCertificate','attendanceCertificate','fitnessCertificate'].includes(template.type));
  }
  async function json(req, maximum = 64 * 1024) {
    requireThat(req.headers['content-type']?.split(';')[0] === 'application/json', 415, 'Use JSON requests.');
    const chunks = []; let length = 0;
    for await (const chunk of req) { length += chunk.length; requireThat(length <= maximum, 413, 'Request too large.'); chunks.push(chunk); }
    try { return JSON.parse(Buffer.concat(chunks).toString()); } catch { throw new ApiError(400, 'Invalid JSON.'); }
  }
  async function dispatch(req, url, body) {
    const path = url.pathname, method = req.method;
    if (path === '/api/demo/accounts' && method === 'GET') {
      requireThat(store.get("SELECT value FROM settings WHERE key='synthetic'")?.value==='true',404,'Demo account listing is unavailable.');
      const emails=demoRoster().map(a=>a.sharedEmail);
      return store.all(`SELECT u.id,u.name,u.email,u.job AS professional_role,u.role AS account_type,u.active,d.name AS department FROM users u LEFT JOIN departments d ON d.id=u.department WHERE u.email IN (${emails.map(()=>'?').join(',')}) ORDER BY u.job,u.name`,...emails);
    }
    if (path === '/api/login' && method === 'POST') {
      fields(body, ['email', 'password']);
      limit(`login-ip:${req.socket.remoteAddress}`, 15);
      const email = text(body.email, 254).toLowerCase(); limit(`login-account:${digest(email)}`, 10);
      const user = store.get('SELECT * FROM users WHERE email=?', email);
      // Perform the same expensive hash for an unknown account.
      const check = user ?? { salt: '0'.repeat(32), password_hash: '0'.repeat(64) };
      const matched = passwordMatches(body.password, check);
      requireThat(user?.active && matched, 401, 'Invalid credentials.');
      requireThat(user.role!=='staff'||['doctor','dentist','nurse','receptionist','pharmacist'].includes(user.job),403,'Staff profile is missing or unassigned. Ask an administrator to repair this account.');
      const sessionToken = token();
      store.transaction(() => {
        store.run('INSERT INTO sessions VALUES(?,?,?,?,?,?)', digest(sessionToken), user.id, user.auth_version, now(), now(), now());
        store.audit(user.id, 'session.started', user.id);
      });
      return { token: sessionToken, user: store.safeUser(user), expiresAt: new Date(now() + lifetime).toISOString() };
    }
    if (path.startsWith('/api/verify/') && method === 'GET') {
      limit(`verify:${req.socket.remoteAddress}`, 30);
      const raw = path.slice('/api/verify/'.length);
      requireThat(/^[A-Za-z0-9_-]{43}$/.test(raw), 404, 'Reference unavailable.');
      const document = store.get('SELECT * FROM documents WHERE reference_hash=?', digest(raw));
      requireThat(document && document.render === 'ready', 404, 'Reference unavailable.');
      const fingerprint = url.searchParams.get('sha256');
      requireThat(fingerprint === null || /^[a-f0-9]{64}$/.test(fingerprint));
      return { validity: document.validity, documentType: document.type, issuedAt: new Date(document.issued).toISOString(),
        asOf: new Date(now()).toISOString(), ...(fingerprint === null ? {} : { fileMatch: document.sha256 === fingerprint }) };
    }
    const actor = actorFor(req);
    limit(`session:${actor.session.hash}`, 240);
    if (method !== 'GET') store.run('UPDATE sessions SET touched=? WHERE hash=?', now(), actor.session.hash);
    if (path === '/api/activity' && method === 'POST') { fields(body, []); return { ok: true }; }
    if (path === '/api/session' && method === 'GET') return store.safeUser(actor);
    if (path === '/api/logout' && method === 'POST') { store.run('DELETE FROM sessions WHERE hash=?', actor.session.hash); return { ok: true }; }
    if (path === '/api/reauthenticate' && method === 'POST') {
      fields(body, ['password']); limit(`reauth:${actor.id}`, 10);
      requireThat(passwordMatches(body.password, actor), 401, 'Invalid credentials.');
      store.run('UPDATE sessions SET reauthed=? WHERE hash=?', now(), actor.session.hash); return { ok: true };
    }
    if (path === '/api/people' && method === 'GET') {
      if (actor.role === 'admin') return store.all('SELECT * FROM users').map(u => store.safeUser(u));
      if (actor.role === 'staff') return store.all('SELECT users.* FROM users JOIN care ON users.id=care.patient WHERE care.staff=?', actor.id).map(u => store.safeUser(u));
      return [store.safeUser(actor)];
    }
    if (path === '/api/visits' && method === 'GET') {
      const patientId = text(url.searchParams.get('patientId'), 128);
      store.patientAccess(actor, patientId);
      return store.all('SELECT id,patient,staff,at,status,version FROM visits WHERE patient=? ORDER BY at DESC,id', patientId);
    }
    if (path === '/api/originals' && method === 'GET') {
      const patientId = text(url.searchParams.get('patientId'), 128);
      store.patientAccess(actor, patientId);
      return store.all("SELECT id,sha256,bytes FROM files WHERE patient=? AND purpose='original' ORDER BY id", patientId);
    }
    if (/^\/api\/people\/[^/]+\/active$/.test(path) && method === 'POST') {
      admin(actor); fresh(store, actor); fields(body, ['active', 'reason']); text(body.reason);
      requireThat(typeof body.active === 'boolean'); const userId = path.split('/')[3];
      return store.transaction(() => {
        const user = store.get('SELECT * FROM users WHERE id=?', userId); requireThat(user, 404);
        if (!body.active) {
          requireThat(userId !== actor.id, 400, 'You cannot deactivate yourself.');
          requireThat(user.role !== 'admin' || store.get("SELECT count(*) n FROM users WHERE role='admin' AND active=1").n > 1, 409, 'Keep an active administrator.');
          requireThat(!store.get("SELECT 1 FROM tasks WHERE owner=? AND status NOT IN ('done','dismissed')", userId) &&
            !store.get("SELECT 1 FROM visits WHERE staff=? AND status IN ('booked','confirmed','inProgress')", userId), 409, 'Transfer responsibility before deactivation.');
        }
        store.run('UPDATE users SET active=?,auth_version=auth_version+1 WHERE id=?', body.active ? 1 : 0, userId);
        store.run('DELETE FROM sessions WHERE user_id=?', userId); store.audit(actor.id, 'account.activeChanged', userId);
        return { ok: true };
      });
    }
    if (path === '/api/tasks' && method === 'GET') {
      requireThat(actor.role === 'staff', 403);
      return store.all('SELECT * FROM tasks WHERE owner=? OR (coverage_staff=? AND coverage_until>?) ORDER BY due IS NULL,due,id',actor.id,actor.id,now()).filter(t=>{try{if(t.patient)store.patientAccess(actor,t.patient);return true;}catch(error){if(error.status===403)return false;throw error;}});
    }
    if (path === '/api/tasks' && method === 'POST') {
      fields(body, ['patientId','sourceId','title','kind','dueAt','priority','idempotencyKey']);
      requireThat(actor.role === 'staff', 403); store.patientAccess(actor, body.patientId);
      text(body.sourceId, 200); text(body.title, 200); requireThat(kinds.includes(body.kind));
      requireThat(['routine','high','urgent'].includes(body.priority ?? 'routine'));
      return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
        const existing = store.get('SELECT * FROM tasks WHERE source=?', body.sourceId);
        if (existing) { taskAccess(actor, existing.id); requireThat(existing.patient === body.patientId, 409); return existing; }
        const taskId = id(); store.run('INSERT INTO tasks(id,owner,patient,source,title,kind,priority,due,created) VALUES(?,?,?,?,?,?,?,?,?)',
          taskId, actor.id, body.patientId, body.sourceId, body.title, body.kind, body.priority ?? 'routine', body.dueAt ? date(body.dueAt) : null, now());
        store.audit(actor.id, 'task.created', taskId); return store.get('SELECT * FROM tasks WHERE id=?', taskId);
      }));
    }
    if (/^\/api\/tasks\/[^/]+$/.test(path) && method === 'GET') return taskAccess(actor,path.split('/')[3]);
    if (/^\/api\/tasks\/[^/]+$/.test(path) && method === 'PATCH') {
      fields(body, ['status','expectedVersion','outcome','reviewAt']);
      return store.transaction(() => {
        const task = taskAccess(actor, path.split('/')[3]); version(task, body.expectedVersion);
        requireThat(statuses.includes(body.status)); const outcome = text(body.outcome);
        const reviewAt = body.reviewAt ? date(body.reviewAt) : null;
        requireThat(!['waiting','blocked'].includes(body.status) || reviewAt > now(), 400, 'Choose a future review date.');
        store.run('UPDATE tasks SET status=?,outcome=?,review_at=?,version=version+1 WHERE id=?', body.status, outcome, reviewAt, task.id);
        const updated = store.get('SELECT * FROM tasks WHERE id=?', task.id);
        store.run('INSERT INTO task_history VALUES(?,?,?,?,?,?,?)', id(), task.id, actor.id, now(), JSON.stringify(task), JSON.stringify(updated), outcome);
        store.audit(actor.id, 'task.statusChanged', task.id); return updated;
      });
    }
    if (/^\/api\/tasks\/[^/]+\/history$/.test(path) && method === 'GET') {
      const task = taskAccess(actor, path.split('/')[3]); return store.all('SELECT * FROM task_history WHERE task=? ORDER BY at,id', task.id);
    }
    if (path === '/api/document-workspace' && method === 'GET') {
      const patientId=text(url.searchParams.get('patientId'),128),patient=store.patientAccess(actor,patientId);
      const preparing=actor.role==='staff'&&['doctor','dentist','nurse'].includes(actor.job);
      const documents=store.all('SELECT id,request,patient,type,language,issued,validity,render,version,snapshot FROM documents WHERE patient=? ORDER BY issued DESC,id',patientId).map(d=>({...d,reference:JSON.parse(d.snapshot).verificationReference,snapshot:undefined}));
      return {patientName:patient.name,visits:preparing?store.all("SELECT id,at FROM visits WHERE patient=? AND staff=? AND status='completed' ORDER BY at DESC",patientId,actor.id):[],templates:preparing?store.all('SELECT * FROM templates'):[],requests:preparing?store.all('SELECT * FROM requests WHERE patient=? AND author=? ORDER BY id',patientId,actor.id).map(r=>({...r,content:JSON.parse(r.content)})):[],issued:documents,sources:[]};
    }
    if (path==='/api/document-metadata'&&method==='GET') {
      const d=documentAccess(actor,text(url.searchParams.get('id'),128));return {...d,reference:JSON.parse(d.snapshot).verificationReference,snapshot:undefined,file_id:undefined,sha256:undefined,reference_hash:undefined};
    }
    if(path==='/api/document-delivery'&&method==='POST') {
      fields(body,['id']);const d=documentAccess(actor,text(body.id,128));requireThat(d.issuer===actor.id&&d.validity==='valid',403,'Only the issuer can retry current document delivery.');
      store.run("UPDATE deliveries SET state='pending',next_at=?,last_error=NULL WHERE document=? AND state!='delivered'",now(),d.id);store.audit(actor.id,'document.deliveryRetried',d.id);return {ok:true};
    }
    if(path==='/api/document-replacement'&&method==='POST') {
      fields(body,['id','expectedVersion','content','reason','templateId','idempotencyKey']);const reason=text(body.reason,1000);
      return store.transaction(()=>store.retry(actor.id,body.idempotencyKey,{path,body},()=>{
        const d=documentAccess(actor,text(body.id,128));requireThat(d.issuer===actor.id&&d.validity==='valid',403,'Only the issuer can replace a current document.');version(d,body.expectedVersion);
        const original=store.get('SELECT * FROM requests WHERE id=?',d.request),template=store.get('SELECT * FROM templates WHERE id=?',body.templateId??original.template);requireThat(template,404);signer(actor,template);validateContent(template,body.content);
        const key=id();store.run("INSERT INTO requests(id,patient,visit,template,author,content) VALUES(?,?,?,?,?,?)",key,d.patient,original.visit,template.id,actor.id,JSON.stringify(body.content));
        store.run('INSERT INTO settings(key,value) VALUES(?,?)','document.replaces:'+key,JSON.stringify({id:d.id,version:d.version,reason}));store.audit(actor.id,'document.replacementPrepared',key);return store.get('SELECT * FROM requests WHERE id=?',key);
      }));
    }
    if(path==='/api/document-source-release'&&method==='POST') {
      fields(body,['id','released','reason']);text(body.reason,1000);requireThat(typeof body.released==='boolean'&&actor.role==='staff'&&['doctor','dentist'].includes(actor.job),403,'Responsible clinician access required.');
      const file=store.get("SELECT * FROM files WHERE id=? AND purpose='original'",text(body.id,128));requireThat(file,404,'Source file unavailable.');store.patientAccess(actor,file.patient);
      store.transaction(()=>{store.run('UPDATE files SET released=? WHERE id=?',body.released?1:0,file.id);store.run('INSERT INTO document_events VALUES(?,?,?,?,?,?)',id(),file.id,actor.id,body.released?'sourceReleased':'sourceWithheld',now(),body.reason);store.audit(actor.id,body.released?'document.sourceReleased':'document.sourceWithheld',file.id);});return {ok:true};
    }
    if(path==='/api/document-verification-manifest'&&method==='GET') {
      admin(actor);fresh(store,actor);store.audit(actor.id,'document.verificationManifestExported','clinic');return {generatedAt:new Date(now()).toISOString(),documents:store.all('SELECT id,reference_hash,validity,issued,version FROM documents ORDER BY id')};
    }
    if (/^\/api\/requests\/[^/]+\/preview$/.test(path) && method === 'GET') {
      const request=requestAccess(actor,path.split('/')[3]),template=store.get('SELECT * FROM templates WHERE id=?',request.template),patient=store.get('SELECT * FROM users WHERE id=?',request.patient),visit=store.get('SELECT * FROM visits WHERE id=?',request.visit);
      requireThat(request.author===actor.id,403,'Only the request author can preview.');validateContent(template,JSON.parse(request.content));
      requireThat(typeof renderDocument==='function',503,'Server PDF renderer is not configured.');
      const bytes=await renderDocument({patient:{id:patient.id,name:patient.name},issuer:{id:actor.id,name:actor.name},visit:{id:visit.id,at:visit.at},template,clinic:store.get("SELECT value FROM settings WHERE key='clinicName'")?.value??'',content:JSON.parse(request.content),issuedAt:now(),verificationReference:'DRAFT — NOT VALID'});
      const current=actorFor(req);requestAccess(current,request.id);requireThat(current.id===request.author,403);store.audit(current.id,'document.previewed',request.id);return {binary:bytes,mime:'application/pdf'};
    }
    if (path === '/api/templates' && method === 'GET') {
      requireThat(actor.role !== 'patient', 403); return store.all('SELECT * FROM templates');
    }
    if (path === '/api/templates' && method === 'POST') {
      admin(actor); fresh(store, actor); fields(body, ['type','language','disclosure','wording','approved','reason']); text(body.reason);
      requireThat(Object.hasOwn(requiredContent, body.type)); requireThat(['en','ar'].includes(body.language));
      requireThat(['clinic','employer','school'].includes(body.disclosure)); requireThat(typeof body.approved === 'boolean');
      requireThat(body.disclosure === 'clinic' || ['sickLeaveCertificate','attendanceCertificate','fitnessCertificate'].includes(body.type));
      text(body.wording, 4000);
      const required = ['patientName','visitDate', ...requiredContent[body.type]], placeholders = [...body.wording.matchAll(/\{([^{}]+)\}/g)].map(m => m[1]);
      requireThat(required.every(f => placeholders.includes(f)) && placeholders.every(f => required.includes(f)), 400, 'Keep the required fields without additional disclosures.');
      return store.transaction(() => { const templateId = id();
        store.run('INSERT INTO templates(id,type,language,disclosure,wording,approved) VALUES(?,?,?,?,?,?)', templateId, body.type, body.language, body.disclosure, body.wording, body.approved ? 1 : 0);
        store.audit(actor.id, body.approved ? 'document.policyApproved' : 'document.policyDrafted', templateId);
        return store.get('SELECT * FROM templates WHERE id=?', templateId);
      });
    }
    if (path === '/api/requests' && method === 'GET') {
      const patientId = text(url.searchParams.get('patientId'), 128);
      requireThat(actor.role === 'staff', 403); store.patientAccess(actor, patientId);
      return store.all('SELECT id,patient,template,status,version FROM requests WHERE patient=? AND author=? ORDER BY id', patientId, actor.id);
    }
    if (path === '/api/requests' && method === 'POST') {
      fields(body, ['patientId','visitId','templateId','content','idempotencyKey']); requireThat(actor.role === 'staff', 403);
      store.patientAccess(actor, body.patientId);
      return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, body }, () => {
        const visit = store.get('SELECT * FROM visits WHERE id=?', body.visitId);
        requireThat(visit?.patient === body.patientId && visit.staff === actor.id && visit.status === 'completed', 403, 'Use your completed patient visit.');
        const template = store.get('SELECT * FROM templates WHERE id=?', body.templateId); requireThat(template, 404);
        validateContent(template, body.content); const requestId = id();
        store.run('INSERT INTO requests(id,patient,visit,template,author,content) VALUES(?,?,?,?,?,?)', requestId, body.patientId, visit.id, template.id, actor.id, JSON.stringify(body.content));
        store.audit(actor.id, 'document.prepared', requestId); return store.get('SELECT * FROM requests WHERE id=?', requestId);
      }));
    }
    if (/^\/api\/requests\/[^/]+\/(submit|approve|issue)$/.test(path) && method === 'POST') {
      fields(body, ['expectedVersion','idempotencyKey']); const requestId = path.split('/')[3], action = path.split('/')[4];
      return store.transaction(() => {
        const request = requestAccess(actor, requestId), template = store.get('SELECT * FROM templates WHERE id=?', request.template);
        const operation = () => {
          version(request, body.expectedVersion); validateContent(template, JSON.parse(request.content));
          const visit = store.get('SELECT * FROM visits WHERE id=?', request.visit);
          requireThat(visit.patient === request.patient && visit.staff === actor.id && visit.status === 'completed', 403);
          const expected = { submit: 'draft', approve: 'submitted', issue: 'approved' }[action];
          requireThat(request.status === expected, 409, 'Document request state changed.');
          if (action !== 'submit') signer(actor, template);
          if (action !== 'issue') {
            store.run('UPDATE requests SET status=?,version=version+1 WHERE id=?', action === 'submit' ? 'submitted' : 'approved', requestId);
            store.audit(actor.id, `document.${action}`, requestId); return store.get('SELECT * FROM requests WHERE id=?', requestId);
          }
          const patient = store.get('SELECT * FROM users WHERE id=?', request.patient);
          const clinic = store.get("SELECT value FROM settings WHERE key='clinicName'")?.value;
          requireThat(clinic, 409, 'Configure clinic identity before issuance.');
          const documentId = id(), reference = token();
          const snapshot = { patient: { id: patient.id, name: patient.name }, issuer: { id: actor.id, name: actor.name, credentialUntil: actor.credential_until },
            visit: { id: visit.id, at: visit.at }, template, clinic, content: JSON.parse(request.content), issuedAt: now(), verificationReference: reference };
          store.run('INSERT INTO documents(id,request,patient,issuer,type,language,issued,snapshot,reference_hash) VALUES(?,?,?,?,?,?,?,?,?)',
            documentId, request.id, request.patient, actor.id, template.type, template.language, now(), JSON.stringify(snapshot), digest(reference));
          const replacement=store.get('SELECT value FROM settings WHERE key=?','document.replaces:'+request.id);
          if(replacement){const old=JSON.parse(replacement.value);const changed=store.run("UPDATE documents SET validity='superseded',version=version+1 WHERE id=? AND version=? AND validity='valid'",old.id,old.version);requireThat(changed.changes===1,409,'The replaced document changed. Prepare a fresh replacement.');store.audit(actor.id,'document.superseded',old.id);}
          store.run("UPDATE requests SET status='issued',version=version+1 WHERE id=?", request.id);
          store.run('INSERT INTO deliveries(id,document,recipient,next_at) VALUES(?,?,?,?)', id(), documentId, request.patient, now());
          store.audit(actor.id, 'document.issued', documentId);
          return { ...store.get('SELECT id,patient,type,language,issued,validity,render,version FROM documents WHERE id=?', documentId), reference };
        };
        return action === 'issue' ? store.retry(actor.id, body.idempotencyKey, { path, body }, operation) : operation();
      });
    }
    if (path === '/api/documents' && method === 'GET') {
      const patientId = text(url.searchParams.get('patientId'), 128);
      store.patientAccess(actor, patientId, { administrative: true });
      return store.all('SELECT id,request,patient,type,language,issued,validity,render,version FROM documents WHERE patient=? ORDER BY issued DESC,id', patientId);
    }
    if (/^\/api\/documents\/[^/]+\/render$/.test(path) && method === 'POST') {
      fields(body, []); const document = documentAccess(actor, path.split('/')[3]);
      requireThat(actor.role === 'staff' && document.issuer === actor.id, 403);
      if (document.render === 'ready') return { id: document.id, render: 'ready' };
      requireThat(typeof renderDocument === 'function', 503, 'Server PDF renderer is not configured.');
      const snapshot = JSON.parse(document.snapshot), bytes = await renderDocument(snapshot);
      requireThat(Buffer.isBuffer(bytes) && bytes.subarray(0,5).toString() === '%PDF-', 502, 'Renderer did not return a PDF.');
      // Re-authorize after awaiting a provider and recheck current qualification.
      const current = actorFor(req); documentAccess(current, document.id); signer(current, snapshot.template);
      return store.transaction(() => {
        const latest = store.get('SELECT * FROM documents WHERE id=?', document.id);
        requireThat(latest.validity === 'valid', 409, 'Document validity changed.');
        if (latest.render === 'ready') return { id: latest.id, render: 'ready' };
        const fileId = store.putFile(document.patient, bytes, 'issued');
        store.run("UPDATE documents SET file_id=?,sha256=?,render='ready' WHERE id=?", fileId, digest(bytes), document.id);
        store.audit(current.id, 'document.rendered', document.id); return { id: document.id, render: 'ready' };
      });
    }
    if (/^\/api\/documents\/[^/]+\/download$/.test(path) && method === 'GET') {
      const document = documentAccess(actor, path.split('/')[3]);
      requireThat(document.render === 'ready', 409, 'The issued PDF is not ready.');
      const bytes = store.readFile(document.file_id); store.audit(actor.id, 'document.downloaded', document.id);
      return { binary: bytes, mime: 'application/pdf' };
    }
    if (/^\/api\/documents\/[^/]+\/revoke$/.test(path) && method === 'POST') {
      fields(body, ['reason','expectedVersion']); text(body.reason); fresh(store, actor);
      return store.transaction(() => {
        const document = documentAccess(actor, path.split('/')[3]); requireThat(document.issuer === actor.id && ['doctor','dentist'].includes(actor.job), 403);
        version(document, body.expectedVersion); store.run("UPDATE documents SET validity='revoked',version=version+1 WHERE id=?", document.id);
        store.run('INSERT INTO document_events VALUES(?,?,?,?,?,?)',id(),document.id,actor.id,'revoked',now(),body.reason);
        store.audit(actor.id, 'document.revoked', document.id); return { ok: true };
      });
    }
    if (path === '/api/originals' && method === 'POST') {
      fields(body, ['patientId','base64','idempotencyKey']); store.patientAccess(actor, body.patientId);
      requireThat(typeof body.base64 === 'string' && /^[A-Za-z0-9+/]*={0,2}$/.test(body.base64));
      const bytes = Buffer.from(body.base64, 'base64'); requireThat(bytes.subarray(0, 5).toString() === '%PDF-', 400, 'Only PDF originals are supported here.');
      return store.transaction(() => store.retry(actor.id, body.idempotencyKey, { path, hash: digest(bytes), patient: body.patientId }, () => {
        const fileId = store.putFile(body.patientId, bytes, 'original'); store.audit(actor.id, 'original.uploaded', fileId); return { id: fileId, sha256: digest(bytes) };
      }));
    }
    if (/^\/api\/originals\/[^/]+$/.test(path) && method === 'GET') {
      const fileId = path.split('/')[3], file = store.get("SELECT * FROM files WHERE id=? AND purpose='original'", fileId); requireThat(file, 404);
      store.patientAccess(actor, file.patient); return { binary: store.readFile(fileId), mime: 'application/pdf' };
    }
    if (path === '/api/notifications' && method === 'GET') return store.all('SELECT id,message,at FROM notifications WHERE recipient=? ORDER BY at DESC', actor.id);
    if (path === '/api/ai' && method === 'POST') {
      fields(body, ['patientId','prompt']); requireThat(actor.role === 'staff', 403); store.patientAccess(actor, body.patientId); text(body.prompt, 8000);
      requireThat(typeof aiProvider === 'function', 503, 'Server AI provider is not configured.');
      const answer = await aiProvider(body.prompt); const current = actorFor(req); store.patientAccess(current, body.patientId);
      return { draft: true, answer };
    }
    if (path === '/api/reports/explain' && method === 'POST') {
      // A patient's own uploaded PDF original (or one a current care-team
      // clinician may see). The client sends the text it extracted; the
      // server checks the file belongs to that patient, holds the provider
      // key, discloses partial coverage and returns a labelled draft.
      fields(body, ['patientId','fileId','text']);
      requireThat(actor.role === 'patient' || actor.role === 'staff', 403, 'Patient or care-team access required.');
      store.patientAccess(actor, body.patientId);
      requireThat(typeof body.fileId === 'string' && /^[a-f0-9-]{36}$/.test(body.fileId));
      const file = store.get("SELECT * FROM files WHERE id=? AND purpose='original'", body.fileId);
      requireThat(file && file.patient === body.patientId, 404, 'Report unavailable.');
      const reportText = text(body.text, 50000);
      limit(`explain:${actor.id}`, 10);
      requireThat(typeof reportExplainer === 'function', 503, 'Report explanation is not configured on the server.');
      const { document, coverage } = clipReport(reportText);
      let answer;
      try { answer = await reportExplainer({ instructions: REPORT_INSTRUCTIONS, document }); }
      catch { throw new ApiError(502, 'The explanation service failed. Try again later.'); }
      // Re-check: access may have been revoked while the provider was working.
      store.patientAccess(actorFor(req), body.patientId);
      store.audit(actor.id, 'report.explained', body.fileId);
      return { draft: true, answer, coverage };
    }
    if (path === '/api/reports/chat' && method === 'POST') {
      // A grounded follow-up about the same authorized PDF original.
      fields(body, ['patientId','fileId','text','question','history']);
      requireThat(actor.role === 'patient' || actor.role === 'staff', 403, 'Patient or care-team access required.');
      store.patientAccess(actor, body.patientId);
      requireThat(typeof body.fileId === 'string' && /^[a-f0-9-]{36}$/.test(body.fileId));
      const file = store.get("SELECT * FROM files WHERE id=? AND purpose='original'", body.fileId);
      requireThat(file && file.patient === body.patientId, 404, 'Report unavailable.');
      limit(`chat:${actor.id}`, 20);
      requireThat(typeof reportChat === 'function', 503, 'Report questions are not configured on the server.');
      let reply;
      try { reply = await answerReportQuestion(reportChat, body); }
      catch (error) {
        if (/^Invalid /.test(error.message)) throw new ApiError(400, error.message);
        throw new ApiError(502, 'The answer service failed. Try again later.');
      }
      store.patientAccess(actorFor(req), body.patientId);
      store.audit(actor.id, 'report.question', body.fileId);
      return reply;
    }
    if (path === '/api/health' && method === 'GET') {
      admin(actor);
      return { schema: store.get('PRAGMA user_version').user_version, storage: store.get('PRAGMA quick_check').quick_check === 'ok' ? 'ok' : 'failed',
        jobs: store.all('SELECT * FROM jobs'), failedDelivery: store.get("SELECT count(*) n FROM deliveries WHERE state='failed'").n,
        pendingDelivery: store.get("SELECT count(*) n FROM deliveries WHERE state='pending'").n,
        aiConfigured: !!aiProvider, reportExplainerConfigured: !!reportExplainer, reportChatConfigured: !!reportChat, pdfRendererConfigured: !!renderDocument,
        payments: 'deskRecordOnly', externalDelivery: 'notConfigured', inAppDelivery: 'serverWorker' };
    }
    const ops = dutyOps({ store, now, path, method, url, body, actor }) ?? workforceOps({ store, now, path, method, url, body, actor }) ?? workspaceOps({ store, now, path, method, url, body, actor }) ?? clinicOps({ store, now, path, method, url, body, actor }) ??
      clinicalOps({ store, now, path, method, url, body, actor });
    if (ops !== undefined) return ops;
    throw new ApiError(404, 'Endpoint unavailable.');
  }
  const server = createServer(async (req, res) => {
    const started = performance.now();
    const headers = { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'" };
    try {
      const origin = req.headers.origin;
      requireThat(!origin || origins.includes(origin), 403, 'Origin not allowed.');
      if (origin) Object.assign(headers, { 'Access-Control-Allow-Origin': origin, Vary: 'Origin' });
      if (req.method === 'OPTIONS') {
        res.writeHead(204, { ...headers, 'Access-Control-Allow-Methods': 'GET,POST,PATCH,OPTIONS', 'Access-Control-Allow-Headers': 'Authorization,Content-Type' }); res.end(); return;
      }
      const url = new URL(req.url, 'http://localhost');
      const upload = url.pathname === '/api/originals' && req.method === 'POST';
      if (upload) actorFor(req);
      // Report endpoints carry extracted text (UTF-8, possibly Arabic) and
      // a bounded conversation; everything else stays at 64 KB.
      const report = ['/api/reports/explain','/api/reports/chat'].includes(url.pathname);
      const body = ['POST','PATCH'].includes(req.method)
        ? await json(req, upload ? 28 * 1024 * 1024 : report ? 192 * 1024 : 64 * 1024) : null;
      // Authorization occurs after body reading, so revocation during uploads is honored.
      const result = await dispatch(req, url, body);
      res.writeHead(200, { ...headers, 'Content-Type': result?.binary ? result.mime : 'application/json',
        'Server-Timing': `request;dur=${(performance.now() - started).toFixed(1)}` });
      res.end(result?.binary ?? JSON.stringify(result));
    } catch (error) {
      const status = error instanceof ApiError ? error.status : 500;
      res.writeHead(status, { ...headers, 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: error instanceof ApiError ? error.message : 'Server could not complete the request.' }));
    }
  });
  server.requestTimeout = 30000; server.headersTimeout = 15000;
  return server;
}
