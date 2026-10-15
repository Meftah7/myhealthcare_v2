import { DatabaseSync } from 'node:sqlite';
import { mkdirSync, statSync, readFileSync, writeFileSync, renameSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { randomBytes, randomUUID, createHash, scryptSync, timingSafeEqual,
  createCipheriv, createDecipheriv } from 'node:crypto';

export const digest = value => createHash('sha256').update(value).digest('hex');
export const id = () => randomUUID();
export const token = () => randomBytes(32).toString('base64url');
export class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
export function requireThat(condition, status = 400, message = 'Invalid request.') {
  if (!condition) throw new ApiError(status, message);
}
export function text(value, max = 2000) {
  requireThat(typeof value === 'string' && value.trim().length > 0 && value.length <= max);
  return value.trim();
}
export function fields(value, allowed) {
  requireThat(value && !Array.isArray(value) && typeof value === 'object' &&
    Object.keys(value).every(key => allowed.includes(key)));
}
export function passwordHash(password, salt = randomBytes(16).toString('hex')) {
  text(password, 256);
  requireThat(password.length >= 12, 400, 'Use at least 12 password characters.');
  return { salt, hash: scryptSync(password, salt, 32, { N: 32768, maxmem: 64 * 1024 * 1024 }).toString('hex') };
}
export function passwordMatches(password, user) {
  if (typeof password !== 'string' || password.length > 256) return false;
  const computed = scryptSync(password, user.salt, 32, { N: 32768, maxmem: 64 * 1024 * 1024 });
  return timingSafeEqual(computed, Buffer.from(user.password_hash, 'hex'));
}
export function encrypt(bytes, key) {
  const nonce = randomBytes(12), cipher = createCipheriv('aes-256-gcm', key, nonce);
  return Buffer.concat([Buffer.from('MHC1'), nonce,
    cipher.update(bytes), cipher.final(), cipher.getAuthTag()]);
}
export function decrypt(bytes, key) {
  requireThat(bytes.subarray(0, 4).toString() === 'MHC1', 400, 'Invalid encrypted archive.');
  const cipher = createDecipheriv('aes-256-gcm', key, bytes.subarray(4, 16));
  cipher.setAuthTag(bytes.subarray(-16));
  return Buffer.concat([cipher.update(bytes.subarray(16, -16)), cipher.final()]);
}

export class Store {
  constructor({ directory, fileKey, now = Date.now }) {
    requireThat(/^[a-f0-9]{64}$/.test(fileKey), 500, 'Provide a 32-byte server file key.');
    this.directory = resolve(directory); this.fileKey = Buffer.from(fileKey, 'hex'); this.now = now;
    requireThat(!existsSync(join(this.directory, '.restore-incomplete')), 500, 'Incomplete restore is quarantined.');
    mkdirSync(this.directory, { recursive: true, mode: 0o700 });
    mkdirSync(join(this.directory, 'files'), { recursive: true, mode: 0o700 });
    this.db = new DatabaseSync(join(this.directory, 'clinic.sqlite'), { timeout: 5000 });
    this.db.exec('PRAGMA journal_mode=WAL; PRAGMA foreign_keys=ON; PRAGMA synchronous=FULL;');
    const version = this.db.prepare('PRAGMA user_version').get().user_version;
    requireThat(version <= 3, 500, 'Database is newer than this server.');
    if (version === 0) this.db.exec(`BEGIN IMMEDIATE;
      CREATE TABLE users (id TEXT PRIMARY KEY, email TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('patient','staff','admin')), job TEXT,
        active INTEGER NOT NULL DEFAULT 1, password_hash TEXT NOT NULL, salt TEXT NOT NULL,
        auth_version INTEGER NOT NULL DEFAULT 1, credential_until INTEGER);
      CREATE TABLE sessions (hash TEXT PRIMARY KEY, user_id TEXT NOT NULL REFERENCES users(id),
        auth_version INTEGER NOT NULL, created INTEGER NOT NULL, touched INTEGER NOT NULL, reauthed INTEGER NOT NULL);
      CREATE TABLE care (patient TEXT REFERENCES users(id), staff TEXT REFERENCES users(id),
        PRIMARY KEY(patient,staff));
      CREATE TABLE visits (id TEXT PRIMARY KEY, patient TEXT REFERENCES users(id), staff TEXT REFERENCES users(id),
        at INTEGER NOT NULL, status TEXT NOT NULL, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE tasks (id TEXT PRIMARY KEY, owner TEXT REFERENCES users(id), patient TEXT REFERENCES users(id),
        source TEXT UNIQUE NOT NULL, title TEXT NOT NULL, kind TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'open',
        priority TEXT NOT NULL DEFAULT 'routine', due INTEGER, review_at INTEGER, created INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1, outcome TEXT);
      CREATE TABLE task_history (id TEXT PRIMARY KEY, task TEXT REFERENCES tasks(id), actor TEXT REFERENCES users(id),
        at INTEGER NOT NULL, before_json TEXT NOT NULL, after_json TEXT NOT NULL, reason TEXT NOT NULL);
      CREATE TABLE templates (id TEXT PRIMARY KEY, type TEXT NOT NULL, language TEXT NOT NULL,
        disclosure TEXT NOT NULL, wording TEXT NOT NULL, approved INTEGER NOT NULL DEFAULT 0,
        version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE requests (id TEXT PRIMARY KEY, patient TEXT REFERENCES users(id), visit TEXT REFERENCES visits(id),
        template TEXT REFERENCES templates(id), author TEXT REFERENCES users(id), content TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'draft', version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE documents (id TEXT PRIMARY KEY, request TEXT UNIQUE REFERENCES requests(id),
        patient TEXT REFERENCES users(id), issuer TEXT REFERENCES users(id), type TEXT NOT NULL,
        language TEXT NOT NULL, issued INTEGER NOT NULL, snapshot TEXT NOT NULL, reference_hash TEXT UNIQUE NOT NULL,
        validity TEXT NOT NULL DEFAULT 'valid', render TEXT NOT NULL DEFAULT 'pending',
        file_id TEXT, sha256 TEXT, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE files (id TEXT PRIMARY KEY, patient TEXT REFERENCES users(id), sha256 TEXT NOT NULL,
        bytes INTEGER NOT NULL, purpose TEXT NOT NULL);
      CREATE TABLE deliveries (id TEXT PRIMARY KEY, document TEXT UNIQUE REFERENCES documents(id),
        recipient TEXT REFERENCES users(id), state TEXT NOT NULL DEFAULT 'pending',
        attempts INTEGER NOT NULL DEFAULT 0, next_at INTEGER NOT NULL, last_error TEXT);
      CREATE TABLE notifications (id TEXT PRIMARY KEY, recipient TEXT REFERENCES users(id),
        source TEXT UNIQUE NOT NULL, message TEXT NOT NULL, at INTEGER NOT NULL);
      CREATE TABLE audit (seq INTEGER PRIMARY KEY AUTOINCREMENT, actor TEXT REFERENCES users(id),
        action TEXT NOT NULL, entity TEXT NOT NULL, at INTEGER NOT NULL);
      CREATE TABLE retries (actor TEXT REFERENCES users(id), key TEXT NOT NULL, fingerprint TEXT NOT NULL,
        result TEXT NOT NULL, PRIMARY KEY(actor,key));
      CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
      CREATE TABLE jobs (key TEXT PRIMARY KEY, at INTEGER, status TEXT NOT NULL, detail TEXT);
      CREATE TRIGGER audit_no_update BEFORE UPDATE ON audit BEGIN SELECT RAISE(ABORT,'immutable audit'); END;
      CREATE TRIGGER audit_no_delete BEFORE DELETE ON audit BEGIN SELECT RAISE(ABORT,'immutable audit'); END;
      CREATE TRIGGER history_no_update BEFORE UPDATE ON task_history BEGIN SELECT RAISE(ABORT,'immutable history'); END;
      CREATE TRIGGER history_no_delete BEFORE DELETE ON task_history BEGIN SELECT RAISE(ABORT,'immutable history'); END;
      CREATE TRIGGER issued_immutable BEFORE UPDATE OF snapshot,issued,issuer,patient,type,language,reference_hash ON documents
        BEGIN SELECT RAISE(ABORT,'immutable issued snapshot'); END;
      PRAGMA user_version=1; COMMIT;`);
    // v2: appointments, secure messages and desk billing for the shared mode.
    // Money is integer fils (1 BHD = 1000 fils); payments are append-only.
    if (this.db.prepare('PRAGMA user_version').get().user_version < 2) this.db.exec(`BEGIN IMMEDIATE;
      CREATE TABLE appointments (id TEXT PRIMARY KEY, patient TEXT NOT NULL REFERENCES users(id),
        staff TEXT NOT NULL REFERENCES users(id), start INTEGER NOT NULL, end INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'booked'
          CHECK(status IN ('booked','checkedIn','inProgress','completed','cancelled','noShow')),
        reason TEXT, booked_by TEXT NOT NULL REFERENCES users(id), checked_in INTEGER,
        visit_type TEXT NOT NULL DEFAULT 'followUp', booked_at INTEGER,
        version INTEGER NOT NULL DEFAULT 1);
      CREATE INDEX appointments_staff_time ON appointments(staff, start);
      CREATE TABLE messages (id TEXT PRIMARY KEY, patient TEXT NOT NULL REFERENCES users(id),
        staff TEXT NOT NULL REFERENCES users(id), sender TEXT NOT NULL REFERENCES users(id),
        body TEXT NOT NULL, at INTEGER NOT NULL, read_at INTEGER);
      CREATE INDEX messages_thread ON messages(patient, staff, at);
      CREATE TABLE invoices (id TEXT PRIMARY KEY, patient TEXT NOT NULL REFERENCES users(id),
        description TEXT NOT NULL, amount_fils INTEGER NOT NULL CHECK(amount_fils > 0),
        paid_fils INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'outstanding'
        CHECK(status IN ('outstanding','paid')), created INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE payments (id TEXT PRIMARY KEY, invoice TEXT NOT NULL REFERENCES invoices(id),
        amount_fils INTEGER NOT NULL CHECK(amount_fils > 0), method TEXT NOT NULL CHECK(method IN ('desk')),
        recorded_by TEXT NOT NULL REFERENCES users(id), at INTEGER NOT NULL);
      CREATE TRIGGER payments_no_update BEFORE UPDATE ON payments BEGIN SELECT RAISE(ABORT,'immutable payment'); END;
      CREATE TRIGGER payments_no_delete BEFORE DELETE ON payments BEGIN SELECT RAISE(ABORT,'immutable payment'); END;
      ALTER TABLE users ADD COLUMN department TEXT;
      ALTER TABLE users ADD COLUMN specialty TEXT;
      CREATE TABLE departments (id TEXT PRIMARY KEY, name TEXT UNIQUE NOT NULL, description TEXT);
      CREATE TABLE schedules (staff TEXT NOT NULL REFERENCES users(id), weekday INTEGER NOT NULL CHECK(weekday BETWEEN 1 AND 7),
        start_min INTEGER NOT NULL, end_min INTEGER NOT NULL, slot_min INTEGER NOT NULL DEFAULT 20,
        PRIMARY KEY(staff, weekday), CHECK(start_min < end_min));
      CREATE TABLE encounter_drafts (appointment TEXT PRIMARY KEY REFERENCES appointments(id), patient TEXT NOT NULL REFERENCES users(id),
        author TEXT NOT NULL REFERENCES users(id), note TEXT NOT NULL DEFAULT '', meds TEXT NOT NULL DEFAULT '[]',
        updated INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE signed_notes (appointment TEXT PRIMARY KEY REFERENCES appointments(id), patient TEXT NOT NULL REFERENCES users(id),
        signer TEXT NOT NULL REFERENCES users(id), note TEXT NOT NULL, outcome TEXT, signed_at INTEGER NOT NULL);
      CREATE TRIGGER signed_notes_no_update BEFORE UPDATE ON signed_notes BEGIN SELECT RAISE(ABORT,'immutable signed note'); END;
      CREATE TRIGGER signed_notes_no_delete BEFORE DELETE ON signed_notes BEGIN SELECT RAISE(ABORT,'immutable signed note'); END;
      CREATE TABLE prescriptions (id TEXT PRIMARY KEY, patient TEXT NOT NULL REFERENCES users(id),
        prescriber TEXT NOT NULL REFERENCES users(id), appointment TEXT REFERENCES appointments(id),
        name TEXT NOT NULL, dose TEXT, frequency TEXT, start INTEGER NOT NULL, active INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE stock (id TEXT PRIMARY KEY, item TEXT NOT NULL, batch TEXT NOT NULL, expiry INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity >= 0), unit TEXT NOT NULL DEFAULT 'units',
        received_by TEXT NOT NULL REFERENCES users(id), received_at INTEGER NOT NULL, version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE dispenses (id TEXT PRIMARY KEY, prescription TEXT NOT NULL REFERENCES prescriptions(id),
        patient TEXT NOT NULL REFERENCES users(id), pharmacist TEXT NOT NULL REFERENCES users(id),
        outcome TEXT NOT NULL CHECK(outcome IN ('dispensed','partial','held','clarificationRequested')),
        quantity TEXT, batch TEXT, expiry INTEGER, note TEXT, stock TEXT REFERENCES stock(id), units INTEGER, at INTEGER NOT NULL);
      CREATE TRIGGER dispenses_no_update BEFORE UPDATE ON dispenses BEGIN SELECT RAISE(ABORT,'immutable dispense'); END;
      CREATE TRIGGER dispenses_no_delete BEFORE DELETE ON dispenses BEGIN SELECT RAISE(ABORT,'immutable dispense'); END;
      CREATE TABLE dental (id TEXT PRIMARY KEY, patient TEXT NOT NULL REFERENCES users(id),
        appointment TEXT NOT NULL REFERENCES appointments(id), tooth INTEGER NOT NULL,
        kind TEXT NOT NULL CHECK(kind IN ('observation','planned','completed')), surface TEXT, note TEXT NOT NULL,
        fulfils TEXT REFERENCES dental(id), author TEXT NOT NULL REFERENCES users(id), at INTEGER NOT NULL);
      CREATE TRIGGER dental_no_update BEFORE UPDATE ON dental BEGIN SELECT RAISE(ABORT,'immutable dental entry'); END;
      CREATE TRIGGER dental_no_delete BEFORE DELETE ON dental BEGIN SELECT RAISE(ABORT,'immutable dental entry'); END;
      PRAGMA user_version=2; COMMIT;`);
    if (this.get('PRAGMA user_version').user_version < 3) this.db.exec(`BEGIN IMMEDIATE;
      ALTER TABLE users ADD COLUMN gender TEXT;
      ALTER TABLE users ADD COLUMN national_id TEXT;
      ALTER TABLE users ADD COLUMN dob INTEGER;
      ALTER TABLE users ADD COLUMN conditions TEXT NOT NULL DEFAULT '[]';
      ALTER TABLE appointments ADD COLUMN completed_at INTEGER;
      ALTER TABLE prescriptions ADD COLUMN issued_at INTEGER;
      UPDATE prescriptions SET issued_at=(SELECT signed_at FROM signed_notes WHERE appointment=prescriptions.appointment);
      ALTER TABLE appointments ADD COLUMN room_label TEXT;
      CREATE TABLE rooms(id TEXT PRIMARY KEY,display_label TEXT NOT NULL,department_id TEXT REFERENCES departments(id),enabled INTEGER NOT NULL DEFAULT 1,version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE encounter_participants(appointment TEXT REFERENCES appointments(id),staff TEXT REFERENCES users(id),participated_at INTEGER NOT NULL,recorded_by TEXT REFERENCES users(id),PRIMARY KEY(appointment,staff));
      CREATE TABLE schedule_exceptions(id TEXT PRIMARY KEY,staff TEXT REFERENCES users(id),start INTEGER NOT NULL,end INTEGER NOT NULL,CHECK(start<end));
      CREATE TABLE feedback(id TEXT PRIMARY KEY,reporter TEXT REFERENCES users(id),category TEXT NOT NULL,message TEXT NOT NULL,created INTEGER NOT NULL,status TEXT NOT NULL DEFAULT 'open',handler TEXT REFERENCES users(id),handled INTEGER,version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE referral_requests(id TEXT PRIMARY KEY,patient TEXT NOT NULL REFERENCES users(id),appointment TEXT REFERENCES appointments(id),requested_by TEXT NOT NULL REFERENCES users(id),reason TEXT NOT NULL,status TEXT NOT NULL DEFAULT 'pending',created INTEGER NOT NULL,version INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE payment_refunds(id TEXT PRIMARY KEY,payment TEXT NOT NULL REFERENCES payments(id),amount_fils INTEGER NOT NULL CHECK(amount_fils>0),status TEXT NOT NULL CHECK(status IN ('pending','settled','failed')),settled_at INTEGER,recorded_by TEXT NOT NULL REFERENCES users(id),reason TEXT NOT NULL);
      CREATE TRIGGER refunds_no_update BEFORE UPDATE ON payment_refunds WHEN OLD.status='settled' BEGIN SELECT RAISE(ABORT,'immutable settled refund'); END;
      CREATE TRIGGER refunds_no_delete BEFORE DELETE ON payment_refunds BEGIN SELECT RAISE(ABORT,'immutable refund'); END;
      CREATE TRIGGER prescription_issued AFTER INSERT ON prescriptions WHEN NEW.issued_at IS NULL BEGIN UPDATE prescriptions SET issued_at=CAST(unixepoch('subsec')*1000 AS INTEGER) WHERE id=NEW.id; END;
      CREATE TRIGGER appointment_completed AFTER UPDATE OF status ON appointments WHEN NEW.status='completed' AND OLD.status!='completed' BEGIN UPDATE appointments SET completed_at=COALESCE(completed_at,CAST(unixepoch('subsec')*1000 AS INTEGER)) WHERE id=NEW.id; END;
      PRAGMA user_version=3; COMMIT;`);
    const keyDigest = digest(this.fileKey);
    const storedKey = this.get("SELECT value FROM settings WHERE key='fileKeyDigest'");
    requireThat(!storedKey || storedKey.value === keyDigest, 500, 'File key does not match this database.');
    this.run("INSERT OR IGNORE INTO settings VALUES('fileKeyDigest',?)", keyDigest);
  }
  close() { this.db.close(); }
  get(sql, ...args) { return this.db.prepare(sql).get(...args); }
  all(sql, ...args) { return this.db.prepare(sql).all(...args); }
  run(sql, ...args) { return this.db.prepare(sql).run(...args); }
  transaction(body) {
    this.db.exec('BEGIN IMMEDIATE');
    try { const result = body(); this.db.exec('COMMIT'); return result; }
    catch (error) { this.db.exec('ROLLBACK'); throw error; }
  }
  audit(actor, action, entity) {
    this.run('INSERT INTO audit(actor,action,entity,at) VALUES(?,?,?,?)', actor, action, entity, this.now());
  }
  retry(actor, key, input, body) {
    text(key, 128);
    const fingerprint = digest(JSON.stringify(input));
    const previous = this.get('SELECT * FROM retries WHERE actor=? AND key=?', actor, key);
    if (previous) {
      requireThat(previous.fingerprint === fingerprint, 409, 'Retry key belongs to different inputs.');
      return JSON.parse(previous.result);
    }
    const result = body();
    this.run('INSERT INTO retries VALUES(?,?,?,?)', actor, key, fingerprint, JSON.stringify(result));
    return result;
  }
  addUser({ email, name, role, job = null, password, credentialUntil = null }) {
    requireThat(['patient', 'staff', 'admin'].includes(role));
    requireThat(role === 'staff' ? ['doctor', 'nurse', 'receptionist', 'pharmacist', 'dentist'].includes(job) : job === null);
    const userId = id(), passwordData = passwordHash(password);
    this.run('INSERT INTO users(id,email,name,role,job,password_hash,salt,credential_until) VALUES(?,?,?,?,?,?,?,?)',
      userId, text(email, 254).toLowerCase(), text(name, 200), role, job, passwordData.hash, passwordData.salt, credentialUntil);
    return userId;
  }
  safeUser(u) { return { id: u.id, fullName: u.name, email: u.email, role: u.role, job: u.job, isActive: !!u.active }; }
  patientAccess(actor, patient, { administrative = false } = {}) {
    const subject = this.get("SELECT * FROM users WHERE id=? AND role='patient'", patient);
    requireThat(subject, 404, 'Patient unavailable.');
    requireThat(actor.id === patient || administrative && actor.role === 'admin' ||
      actor.role === 'staff' && ['doctor','dentist','nurse'].includes(actor.job) && (
        !!this.get('SELECT 1 FROM care WHERE patient=? AND staff=?', patient, actor.id) ||
        !!this.get('SELECT 1 FROM appointments WHERE patient=? AND staff=?', patient, actor.id) ||
        !!this.get('SELECT 1 FROM encounter_participants ep JOIN appointments a ON a.id=ep.appointment WHERE a.patient=? AND ep.staff=?',patient,actor.id)),
    403, 'Patient access denied.');
    return subject;
  }
  filePath(fileId) { requireThat(/^[a-f0-9-]{36}$/.test(fileId)); return join(this.directory, 'files', `${fileId}.enc`); }
  putFile(patient, bytes, purpose) {
    requireThat(Buffer.isBuffer(bytes) && bytes.length > 0 && bytes.length <= 20 * 1024 * 1024);
    const fileId = id(), path = this.filePath(fileId);
    writeFileSync(`${path}.tmp`, encrypt(bytes, this.fileKey), { mode: 0o600 });
    renameSync(`${path}.tmp`, path);
    this.run('INSERT INTO files VALUES(?,?,?,?,?)', fileId, patient, digest(bytes), bytes.length, purpose);
    return fileId;
  }
  readFile(fileId) {
    const record = this.get('SELECT * FROM files WHERE id=?', fileId);
    requireThat(record, 404, 'File unavailable.');
    requireThat(statSync(this.filePath(fileId)).size <= 21 * 1024 * 1024, 500, 'File integrity check failed.');
    const bytes = decrypt(readFileSync(this.filePath(fileId)), this.fileKey);
    requireThat(digest(bytes) === record.sha256, 500, 'File integrity check failed.');
    return bytes;
  }
}
