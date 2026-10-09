import { createServer } from 'node:http';
import { createHash, createHmac, timingSafeEqual } from 'node:crypto';
import { readFileSync, writeFileSync, renameSync, mkdirSync, statSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const tokenPattern = /^[A-Za-z0-9_-]{43}$/;
const hashPattern = /^[a-f0-9]{64}$/;
const types = new Set(['sickLeaveCertificate', 'attendanceCertificate', 'visitSummary', 'referralLetter',
  'prescriptionCopy', 'releasedLabReport', 'releasedImagingReport', 'fitnessCertificate', 'financeStatement']);
const states = new Set(['valid', 'superseded', 'revoked']);
const hash = value => createHash('sha256').update(value).digest('hex');
const equal = (a, b) => typeof a === 'string' && typeof b === 'string' && a.length === b.length && timingSafeEqual(Buffer.from(a), Buffer.from(b));

function requireKey(key) {
  if (!hashPattern.test(key ?? '')) throw new Error('Set VERIFICATION_SIGNING_KEY to a private 32-byte hex key on the registry host.');
}
export function signRegistry(payload, key) {
  requireKey(key);
  return { payload, signature: createHmac('sha256', Buffer.from(key, 'hex')).update(JSON.stringify(payload)).digest('hex') };
}
function loadRegistry(file, key) {
  if (statSync(file).size > 8 * 1024 * 1024) throw new Error('Registry is too large.');
  const envelope = JSON.parse(readFileSync(file, 'utf8'));
  const signed = signRegistry(envelope.payload, key);
  if (!equal(signed.signature, envelope.signature) || envelope.payload?.schema !== 1) throw new Error('Registry integrity check failed.');
  return envelope.payload;
}

/// Publication is an explicit trusted-host operation, never a public HTTP API.
export function publishManifest(manifest, previous = { schema: 1, records: {} }, now = Date.now()) {
  if (!manifest || manifest.schema !== 1 || Object.keys(manifest).some(k => !['schema', 'exportedAt', 'entries'].includes(k)) ||
      !Array.isArray(manifest.entries) || manifest.entries.length > 10000 ||
      !Number.isFinite(Date.parse(manifest.exportedAt)) || Math.abs(now - Date.parse(manifest.exportedAt)) > 300000) {
    throw new Error('Review a fresh minimal manifest exported within five minutes.');
  }
  const records = { ...previous.records };
  const seen = new Set();
  for (const entry of manifest.entries) {
    if (!entry || Object.keys(entry).sort().join(',') !== 'documentType,issuedAt,sha256,token,validity' ||
        !tokenPattern.test(entry.token) || !types.has(entry.documentType) || !states.has(entry.validity) ||
        !hashPattern.test(entry.sha256) || !Number.isFinite(Date.parse(entry.issuedAt)) || Date.parse(entry.issuedAt) > now + 60000) {
      throw new Error('Manifest contains invalid fields. Patient, clinical and issuer details are not accepted.');
    }
    const id = hash(entry.token);
    if (seen.has(id)) throw new Error('Duplicate reference.');
    seen.add(id);
    const old = records[id];
    if (old && (old.sha256 !== entry.sha256 || old.documentType !== entry.documentType || old.issuedAt !== entry.issuedAt ||
        (old.validity === 'revoked' && entry.validity !== 'revoked') || (old.validity === 'superseded' && entry.validity === 'valid'))) {
      throw new Error('Publication cannot change an issued file or reactivate an invalid version.');
    }
    records[id] = { documentType: entry.documentType, issuedAt: entry.issuedAt, validity: entry.validity,
      sha256: entry.sha256, asOf: manifest.exportedAt, expiresAt: new Date(now + 300000).toISOString() };
  }
  // Omitted entries are retained, but valid ones become stale after five minutes.
  return { schema: 1, records };
}

const page = `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Verify a clinic document</title><link rel="stylesheet" href="/verify.css"><main><h1>Verify a clinic document</h1>
<p>This checks a published clinic registry entry. It is not a certificate-based digital signature.</p>
<p id="result" role="status" aria-live="polite">Checking reference…</p>
<label for="file">Check your PDF against the registered original (maximum 20 MB)</label><input id="file" type="file" accept="application/pdf,.pdf">
<p>The PDF stays on your device. Only its SHA-256 fingerprint is sent.</p>
<p>Validity is reported as of the displayed registry update. A stale entry requires the clinic to publish a fresh update.</p>
<button id="retry" type="button">Check again</button></main><script src="/verify.js" defer></script></html>`;
const script = `const token=location.pathname.split('/').pop(); const result=document.querySelector('#result');
async function check(fingerprint) { try {
 const r=await fetch('/api/v/'+encodeURIComponent(token)+(fingerprint?'?sha256='+fingerprint:''),{cache:'no-store',credentials:'omit'});
 const d=await r.json();
 if(r.status===429) { result.textContent='Too many checks. Try again in one minute.'; return; }
 if(!r.ok) { result.textContent=r.status===404?'Reference not found.':'Verification unavailable. Contact the clinic.'; return; }
 result.textContent='Registry status: '+d.validity+'. Type: '+d.documentType+'. Issued: '+d.issuedAt+'. Registry updated: '+d.asOf+
 (fingerprint?(d.fileMatch===true?'. PDF matches the registered original.':d.fileMatch===false?'. PDF DOES NOT match the registered original.':'. File check unavailable for a stale entry.') : '. Select your PDF to check the exact file.');
} catch { result.textContent='Could not verify. Check your connection and retry.'; }}
document.querySelector('#retry').onclick=()=>check();
document.querySelector('#file').onchange=async(e)=>{const file=e.target.files[0];if(!file)return;
 if(file.size>20*1024*1024){result.textContent='Choose a PDF no larger than 20 MB.';return;}
 try{const bytes=new Uint8Array(await file.arrayBuffer());if(String.fromCharCode(...bytes.slice(0,4))!=='%PDF'){result.textContent='Choose a PDF file.';return;}
 const digest=await crypto.subtle.digest('SHA-256',bytes);await check(Array.from(new Uint8Array(digest),b=>b.toString(16).padStart(2,'0')).join(''));}
 catch{result.textContent='File checking requires HTTPS or localhost. Contact the clinic.';}};check();`;
const style = 'body{font:1rem/1.6 system-ui,sans-serif;background:#fafafa;color:#202020;margin:0}main{max-width:42rem;margin:4rem auto;padding:1.5rem}h1{line-height:1.15}input,button{font:inherit;display:block;max-width:100%;margin-top:1rem;padding:.7rem}#result{padding:1rem;border:1px solid #888;overflow-wrap:anywhere}button:focus-visible,input:focus-visible{outline:3px solid #1559b7;outline-offset:3px}';

export function createVerifierServer({ registryPath, key, now = Date.now, rateLimit = 30 }) {
  requireKey(key);
  const buckets = new Map();
  return createServer((req, res) => {
    const headers = { 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'" };
    const send = (status, data, type = 'application/json; charset=utf-8', extra = {}) => {
      res.writeHead(status, { ...headers, 'Content-Type': type, ...extra }); res.end(typeof data === 'string' ? data : JSON.stringify(data));
    };
    if (req.method !== 'GET') return send(405, { error: 'Method not allowed' }, undefined, { Allow: 'GET' });
    let url;
    try { url = new URL(req.url, 'http://localhost'); } catch { return send(400, { error: 'Invalid request' }); }
    if (url.pathname === '/verify.js') return send(200, script, 'text/javascript; charset=utf-8');
    if (url.pathname === '/verify.css') return send(200, style, 'text/css; charset=utf-8');
    if (/^\/v\/[A-Za-z0-9_-]{43}$/.test(url.pathname)) return send(200, page, 'text/html; charset=utf-8');
    if (!url.pathname.startsWith('/api/v/')) return send(404, { validity: 'notFound' });
    const time = now();
    for (const [ip, bucket] of buckets) if (bucket.until <= time) buckets.delete(ip);
    const ip = req.socket.remoteAddress;
    let bucket = buckets.get(ip);
    if (!bucket) { if (buckets.size >= 10000) return send(429, { error: 'Rate limited' }); bucket = { count: 0, until: time + 60000 }; buckets.set(ip, bucket); }
    if (++bucket.count > rateLimit) return send(429, { error: 'Rate limited' }, undefined, { 'Retry-After': '60' });
    const token = url.pathname.slice('/api/v/'.length);
    if (!tokenPattern.test(token)) return send(404, { validity: 'notFound' });
    const fingerprint = url.searchParams.get('sha256');
    if ((fingerprint !== null && !hashPattern.test(fingerprint)) || [...url.searchParams.keys()].some(k => k !== 'sha256')) return send(400, { error: 'Invalid fingerprint' });
    try {
      const row = loadRegistry(registryPath, key).records[hash(token)];
      if (!row) return send(404, { validity: 'notFound' });
      const stale = row.validity === 'valid' && Date.parse(row.expiresAt) <= time;
      send(200, { validity: stale ? 'stale' : row.validity, documentType: row.documentType,
        issuedAt: row.issuedAt, asOf: row.asOf, fileMatch: stale || fingerprint === null ? null : equal(fingerprint, row.sha256) });
    } catch { send(503, { error: 'Registry unavailable' }); }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    const key = process.env.VERIFICATION_SIGNING_KEY;
    requireKey(key);
    const file = resolve(process.env.VERIFICATION_REGISTRY_PATH ?? 'services/document_verification/.state/registry.json');
    if (process.argv[2] === 'import') {
      if (!process.argv.includes('--approve') || !process.argv[3]) throw new Error('Review the exported manifest, then import <manifest.json> --approve on the trusted clinic host.');
      const input = resolve(process.argv[3]);
      if (statSync(input).size > 8 * 1024 * 1024) throw new Error('Manifest is too large.');
      let previous;
      try { previous = loadRegistry(file, key); } catch (error) { if (error.code !== 'ENOENT') throw error; }
      const payload = publishManifest(JSON.parse(readFileSync(input, 'utf8')), previous);
      mkdirSync(dirname(file), { recursive: true });
      const temporary = file + '.tmp';
      writeFileSync(temporary, JSON.stringify(signRegistry(payload, key)), { mode: 0o600 });
      renameSync(temporary, file);
      process.stdout.write('Minimal registry published. Valid entries expire in five minutes unless refreshed.\n');
    } else if (process.argv[2] === 'serve') {
      loadRegistry(file, key);
      createVerifierServer({ registryPath: file, key }).listen(Number(process.env.PORT ?? 8787), process.env.HOST ?? '127.0.0.1',
        () => process.stdout.write('Read-only document verification server started.\n'));
    } else throw new Error('Use import <manifest.json> --approve or serve.');
  } catch (error) { process.stderr.write(error.message + '\n'); process.exitCode = 1; }
}
