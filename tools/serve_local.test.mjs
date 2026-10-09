import { test } from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { createLocalServer } from './serve_local.mjs';

async function listen(server, t) {
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(() => new Promise(r => { server.close(r); server.closeIdleConnections(); }));
  return `http://127.0.0.1:${server.address().port}`;
}

test('static acceptance assets stay inside the selected web root', async t => {
  const directory = mkdtempSync(join(tmpdir(), 'myhealth-local-'));
  t.after(() => {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + '\\') || resolve(directory).startsWith(resolve(tmpdir()) + '/'));
    rmSync(directory, { recursive: true, force: true });
  });
  const root = join(directory, 'web'); mkdirSync(root);
  writeFileSync(join(root, 'index.html'), '<p>Acceptance</p>');
  writeFileSync(join(directory, 'private.txt'), 'Private');
  const base = await listen(createLocalServer(root), t);
  const page = await fetch(base);
  assert.equal(page.headers.get('content-type'), 'text/html');
  assert.equal(await page.text(), '<p>Acceptance</p>');
  assert.equal((await fetch(base + '/%2e%2e%5cprivate.txt')).status, 404);
  assert.equal((await fetch(base, { method: 'POST' })).status, 405);
});

test('same-origin proxy preserves authenticated mutations and exact PDF bytes', async t => {
  const upstream = await listen(createServer((req, res) => {
    assert.equal(req.headers.authorization, 'Bearer synthetic-test-token');
    assert.equal(req.headers.origin, 'http://localhost:8080');
    if (req.method === 'POST') { req.pipe(res); return; }
    res.writeHead(200, { 'Content-Type': 'application/pdf' });
    res.end(Buffer.from([37, 80, 68, 70, 0, 128, 255]));
  }), t);
  const base = await listen(createLocalServer('.', upstream), t);
  const headers = { authorization: 'Bearer synthetic-test-token', origin: 'http://localhost:8080' };
  assert.deepEqual(Buffer.from(await (await fetch(base + '/api/download', { headers })).arrayBuffer()), Buffer.from([37, 80, 68, 70, 0, 128, 255]));
  const reply = await fetch(base + '/api/tasks', { method: 'POST', headers, body: '{"expectedVersion":3}' });
  assert.equal(await reply.text(), '{"expectedVersion":3}');
});

test('local proxy refuses remote or credential-bearing upstream origins', () => {
  for (const origin of ['http://example.com', 'http://user:password@localhost:8787', 'http://localhost:8787/api']) {
    assert.throws(() => createLocalServer('.', origin));
  }
});
