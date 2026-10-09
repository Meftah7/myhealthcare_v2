import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createVerifierServer, publishManifest, signRegistry } from './server.mjs';

const key = 'a'.repeat(64), token = 'b'.repeat(43), fingerprint = 'c'.repeat(64);
const time = Date.parse('2026-10-09T09:00:00Z');
const manifest = (validity = 'valid') => ({ schema: 1, exportedAt: new Date(time).toISOString(), entries: [
  { token, documentType: 'attendanceCertificate', issuedAt: new Date(time - 1000).toISOString(), validity, sha256: fingerprint },
] });

test('publication rejects PHI, duplicates, stale input, changed files and reactivation', () => {
  const first = publishManifest(manifest(), undefined, time);
  assert.ok(!JSON.stringify(first).includes(token));
  for (const change of [m => m.entries[0].patientName = 'Private', m => m.entries.push(m.entries[0]), m => m.exportedAt = '2020-01-01']) {
    const m = manifest(); change(m); assert.throws(() => publishManifest(m, first, time));
  }
  const changed = manifest(); changed.entries[0].sha256 = 'd'.repeat(64);
  assert.throws(() => publishManifest(changed, first, time));
  for (const status of ['revoked', 'superseded']) {
    const invalid = publishManifest(manifest(status), first, time);
    assert.throws(() => publishManifest(manifest(), invalid, time));
  }
  assert.throws(() => signRegistry(first, 'short'));
});

test('public verifier checks fingerprints, privacy, freshness, integrity and read-only methods', async t => {
  const dir = mkdtempSync(join(tmpdir(), 'document-verification-'));
  const registryPath = join(dir, 'registry.json');
  let now = time;
  const payload = publishManifest(manifest(), undefined, time);
  const write = p => writeFileSync(registryPath, JSON.stringify(signRegistry(p, key)));
  write(payload);
  const server = createVerifierServer({ registryPath, key, now: () => now, rateLimit: 100 });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => { await new Promise(resolve => server.close(resolve)); rmSync(dir, { recursive: true }); });
  const base = 'http://127.0.0.1:' + server.address().port;
  const get = path => fetch(base + path);
  let response = await get('/api/v/' + token + '?sha256=' + fingerprint);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('referrer-policy'), 'no-referrer');
  const data = await response.json();
  assert.deepEqual(Object.keys(data).sort(), ['asOf', 'documentType', 'fileMatch', 'issuedAt', 'validity']);
  assert.equal(data.fileMatch, true);
  assert.equal((await (await get('/api/v/' + token + '?sha256=' + 'd'.repeat(64))).json()).fileMatch, false);
  assert.equal((await get('/api/v/' + 'x'.repeat(43))).status, 404);
  assert.equal((await get('/api/v/bad')).status, 404);
  assert.equal((await get('/api/v/' + token + '?sha256=bad')).status, 400);
  assert.equal((await fetch(base + '/api/v/' + token, { method: 'POST', body: 'PDF' })).status, 405);
  assert.match(await (await get('/verify.js')).text(), /crypto.subtle.digest/);
  assert.match(await (await get('/v/' + token)).text(), /PDF stays on your device/);
  now += 300001;
  const stale = await (await get('/api/v/' + token + '?sha256=' + fingerprint)).json();
  assert.equal(stale.validity, 'stale'); assert.equal(stale.fileMatch, null);
  write(publishManifest(manifest('revoked'), payload, time));
  assert.equal((await (await get('/api/v/' + token)).json()).validity, 'revoked');
  const tampered = signRegistry(payload, key); Object.values(tampered.payload.records)[0].validity = 'revoked';
  writeFileSync(registryPath, JSON.stringify(tampered));
  assert.equal((await get('/api/v/' + token)).status, 503);
});

test('rate limit applies to unknown references too', async t => {
  const server = createVerifierServer({ registryPath: 'unused', key, now: () => time, rateLimit: 1 });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const url = 'http://127.0.0.1:' + server.address().port + '/api/v/invalid';
  assert.equal((await fetch(url)).status, 404);
  const limited = await fetch(url);
  assert.equal(limited.status, 429); assert.equal(limited.headers.get('retry-after'), '60');
});
