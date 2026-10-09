import { backup, DatabaseSync } from 'node:sqlite';
import { mkdirSync, readFileSync, writeFileSync, renameSync, readdirSync, unlinkSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { ApiError, decrypt, digest, encrypt, id, requireThat } from './store.mjs';

export function deliverPending(store, { fail = false } = {}) {
  const items = store.all("SELECT deliveries.*,documents.render,documents.validity FROM deliveries JOIN documents ON documents.id=deliveries.document WHERE deliveries.state IN ('pending','failed') AND deliveries.next_at<=? AND deliveries.attempts<8", store.now());
  for (const item of items) store.transaction(() => {
    if (item.validity !== 'valid') {
      store.run("UPDATE deliveries SET state='cancelled' WHERE id=?", item.id); return;
    }
    if (item.render !== 'ready') return;
    const recipient = store.get('SELECT active FROM users WHERE id=?', item.recipient);
    if (!recipient?.active || fail) {
      store.run("UPDATE deliveries SET state='failed',attempts=attempts+1,next_at=?,last_error='delivery_unavailable' WHERE id=?",
        store.now() + Math.min(3600000, 30000 * 2 ** item.attempts), item.id); return;
    }
    store.run('INSERT OR IGNORE INTO notifications VALUES(?,?,?,?,?)', id(), item.recipient,
      `document:${item.document}`, 'A clinic document is ready in your Documents section.', store.now());
    store.run("UPDATE deliveries SET state='delivered',attempts=attempts+1,last_error=NULL WHERE id=?", item.id);
  });
  store.run("INSERT INTO jobs VALUES('delivery',?,'ok',NULL) ON CONFLICT(key) DO UPDATE SET at=excluded.at,status=excluded.status,detail=NULL", store.now());
}

export async function renderPending(store, renderDocument) {
  if (!renderDocument) {
    store.run("INSERT INTO jobs VALUES('render',?,'notConfigured',NULL) ON CONFLICT(key) DO UPDATE SET at=excluded.at,status='notConfigured'", store.now());
    return;
  }
  let failed = false;
  for (const document of store.all("SELECT * FROM documents WHERE validity='valid' AND render IN ('pending','failed') ORDER BY issued,id LIMIT 10")) {
    try {
      const bytes = await renderDocument(JSON.parse(document.snapshot));
      requireThat(Buffer.isBuffer(bytes) && bytes.subarray(0,5).toString() === '%PDF-', 502);
      store.transaction(() => {
        const current = store.get('SELECT * FROM documents WHERE id=?', document.id);
        if (current.validity !== 'valid' || current.render === 'ready') return;
        const fileId = store.putFile(document.patient, bytes, 'issued');
        store.run("UPDATE documents SET file_id=?,sha256=?,render='ready' WHERE id=?", fileId, digest(bytes), document.id);
        store.audit(document.issuer, 'document.workerRendered', document.id);
      });
    } catch {
      failed = true;
      store.run("UPDATE documents SET render='failed' WHERE id=? AND render!='ready'", document.id);
    }
  }
  store.run("INSERT INTO jobs VALUES('render',?,?,NULL) ON CONFLICT(key) DO UPDATE SET at=excluded.at,status=excluded.status", store.now(), failed ? 'failed' : 'ok');
}

export async function encryptedBackup(store, { directory, key, retentionDays = 30 }) {
  requireThat(/^[a-f0-9]{64}$/.test(key), 500, 'Provide a separate 32-byte backup encryption key.');
  requireThat(key !== store.fileKey.toString('hex'), 500, 'Backup encryption must use a separate key.');
  requireThat(Number.isInteger(retentionDays) && retentionDays > 0);
  const backupDirectory = resolve(directory); mkdirSync(backupDirectory, { recursive: true, mode: 0o700 });
  const snapshotPath = join(backupDirectory, `${id()}.snapshot`);
  try {
    await backup(store.db, snapshotPath);
    const snapshot = new DatabaseSync(snapshotPath, { readOnly: true });
    let files;
    try {
      requireThat(snapshot.prepare('PRAGMA integrity_check').get().integrity_check === 'ok', 500);
      files = snapshot.prepare('SELECT * FROM files ORDER BY id').all().map(row => ({
        id: row.id, sha256: row.sha256, bytes: readFileSync(store.filePath(row.id)).toString('base64'),
      }));
    } finally { snapshot.close(); }
    // Bound this initial archive format; larger clinics need a streaming archive.
    const database = readFileSync(snapshotPath);
    requireThat(database.length + files.reduce((n, f) => n + f.bytes.length, 0) < 256 * 1024 * 1024,
      503, 'Backup exceeds the supported archive size. Configure streaming backups before expanding storage.');
    const payload = Buffer.from(JSON.stringify({ schema: 1, created: store.now(), database: database.toString('base64'),
      fileKey: store.fileKey.toString('hex'), files }));
    const name = `backup-${store.now()}-${id()}.mhcb`, path = join(backupDirectory, name);
    writeFileSync(`${path}.tmp`, encrypt(payload, Buffer.from(key, 'hex')), { mode: 0o600 }); renameSync(`${path}.tmp`, path);
    store.run("INSERT INTO jobs VALUES('backup',?,'ok',?) ON CONFLICT(key) DO UPDATE SET at=excluded.at,status='ok',detail=excluded.detail", store.now(), name);
    for (const old of readdirSync(backupDirectory)) {
      const match = /^backup-(\d+)-[a-f0-9-]{36}\.mhcb$/.exec(old);
      if (match && Number(match[1]) < store.now() - retentionDays * 86400000) unlinkSync(join(backupDirectory, old));
    }
    return path;
  } catch (error) {
    store.run("INSERT INTO jobs VALUES('backup',?,'failed','backup_failed') ON CONFLICT(key) DO UPDATE SET at=excluded.at,status='failed',detail=excluded.detail", store.now());
    throw error;
  } finally { if (existsSync(snapshotPath)) unlinkSync(snapshotPath); }
}

// Offline operator capability. The web API has no restore endpoint or key.
// Restore always targets a NEW directory; it never overwrites a live clinic.
export function restoreBackup({ archive, key, directory }) {
  requireThat(/^[a-f0-9]{64}$/.test(key));
  const target = resolve(directory);
  requireThat(!existsSync(target), 409, 'Restore into a new directory, then validate and switch storage offline.');
  const payload = JSON.parse(decrypt(readFileSync(archive), Buffer.from(key, 'hex')).toString());
  requireThat(payload.schema === 1 && /^[a-f0-9]{64}$/.test(payload.fileKey) && Array.isArray(payload.files));
  mkdirSync(join(target, 'files'), { recursive: true, mode: 0o700 });
  const marker = join(target, '.restore-incomplete'); writeFileSync(marker, '', { mode: 0o600 });
  writeFileSync(join(target, 'clinic.sqlite'), Buffer.from(payload.database, 'base64'), { mode: 0o600 });
  const db = new DatabaseSync(join(target, 'clinic.sqlite'));
  try {
    requireThat(db.prepare('PRAGMA integrity_check').get().integrity_check === 'ok', 400, 'Restore integrity failed.');
    requireThat(db.prepare('PRAGMA user_version').get().user_version === 1);
    const expected = db.prepare('SELECT * FROM files').all();
    requireThat(expected.length === payload.files.length);
    const seen = new Set();
    for (const file of payload.files) {
      requireThat(/^[a-f0-9-]{36}$/.test(file.id) && !seen.has(file.id)); seen.add(file.id);
      const row = expected.find(e => e.id === file.id); requireThat(row && row.sha256 === file.sha256);
      const encrypted = Buffer.from(file.bytes, 'base64'), bytes = decrypt(encrypted, Buffer.from(payload.fileKey, 'hex'));
      requireThat(digest(bytes) === row.sha256 && bytes.length === row.bytes);
      writeFileSync(join(target, 'files', `${file.id}.enc`), encrypted, { mode: 0o600 });
    }
    // Restored sessions must never resurrect access that was revoked after backup.
    db.exec('DELETE FROM sessions; UPDATE users SET auth_version=auth_version+1;');
    db.prepare("INSERT INTO jobs VALUES('restore',?,'ok','offline_restore_verified') ON CONFLICT(key) DO UPDATE SET at=excluded.at,status='ok',detail=excluded.detail").run(Date.now());
  } finally { db.close(); }
  writeFileSync(join(target, 'restored-file-key.txt'), payload.fileKey, { mode: 0o600 });
  unlinkSync(marker); return { directory: target, files: payload.files.length };
}

export function startWorkers(store, options) {
  let backingUp = false, rendering = false;
  const deliver = async () => {
    if (rendering) return; rendering = true;
    try { await renderPending(store, options.renderDocument); deliverPending(store); } catch {
    store.run("INSERT INTO jobs VALUES('delivery',?,'failed','worker_failed') ON CONFLICT(key) DO UPDATE SET at=excluded.at,status='failed'", store.now());
    } finally { rendering = false; }
  };
  const runBackup = async () => {
    if (backingUp) return; backingUp = true;
    try { await encryptedBackup(store, options); } catch { /* Health reports failure. */ }
    finally { backingUp = false; }
  };
  deliver(); void runBackup();
  const deliveryTimer = setInterval(deliver, 30000), backupTimer = setInterval(runBackup, 3600000);
  return async () => { clearInterval(deliveryTimer); clearInterval(backupTimer); while (backingUp || rendering) await new Promise(r => setTimeout(r, 10)); };
}

// Basic server renderer for ENGLISH templates only. Unsupported fonts/language
// fail explicitly; never label a malformed or missing-language file ready.
export function renderEnglishPdf(snapshot) {
  if (snapshot.template.language !== 'en') throw new ApiError(503, 'Configure an Arabic-capable server PDF renderer.');
  const values = { ...snapshot.content, patientName: snapshot.patient.name,
    visitDate: new Date(snapshot.visit.at).toISOString().slice(0,10) };
  const wording = snapshot.template.wording.replace(/\{([^{}]+)\}/g, (_, key) => values[key]);
  const text = [snapshot.clinic, wording, `Issued by ${snapshot.issuer.name}`,
    `Issued: ${new Date(snapshot.issuedAt).toISOString()}`,
    ...(snapshot.verificationReference ? [`Verification reference: ${snapshot.verificationReference}`] : [])].join('\n');
  if (/[^\x20-\x7e\n\r]/.test(text)) throw new ApiError(503, 'Configure a server PDF renderer supporting these characters.');
  const lines = text.split(/\r?\n/).flatMap(line => line.match(/.{1,85}(?:\s|$)|.{1,85}/g) ?? ['']);
  const pages = [];
  for (let offset = 0; offset < lines.length; offset += 42) pages.push(lines.slice(offset, offset + 42));
  const objects = ['', '<< /Type /Catalog /Pages 2 0 R >>', '', '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>'];
  const pageIds = [];
  for (const page of pages) {
    const pageId = objects.length, streamId = pageId + 1; pageIds.push(pageId);
    const stream = `BT /F1 11 Tf 14 TL 40 790 Td ${page.map((line, i) => `${i ? 'T* ' : ''}(${line.replace(/[\\()]/g, '\\$&')}) Tj`).join('\n')} ET`;
    objects.push(`<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R >> >> /Contents ${streamId} 0 R >>`,
      `<< /Length ${Buffer.byteLength(stream)} >>\nstream\n${stream}\nendstream`);
  }
  objects[2] = `<< /Type /Pages /Kids [${pageIds.map(i => `${i} 0 R`).join(' ')}] /Count ${pages.length} >>`;
  let pdf = '%PDF-1.4\n', offsets = [0];
  for (let i = 1; i < objects.length; i++) { offsets.push(Buffer.byteLength(pdf)); pdf += `${i} 0 obj\n${objects[i]}\nendobj\n`; }
  const xref = Buffer.byteLength(pdf);
  pdf += `xref\n0 ${objects.length}\n0000000000 65535 f \n${offsets.slice(1).map(n => `${String(n).padStart(10,'0')} 00000 n \n`).join('')}trailer\n<< /Size ${objects.length} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(pdf);
}
