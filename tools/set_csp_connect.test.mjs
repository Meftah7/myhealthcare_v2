import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { exactOrigin, withConnectOrigin } from './set_csp_connect.mjs';

const html = readFileSync(new URL('../web/index.html', import.meta.url), 'utf8');

test('adds exactly the gateway origin to connect-src, once', () => {
  const out = withConnectOrigin(html, 'https://ai.example.org');
  const csp = out.match(/Content-Security-Policy" content="([^"]*)"/)[1];
  const connect = csp.split(';').map(d => d.trim()).find(d => d.startsWith('connect-src'));
  assert.equal(connect, "connect-src 'self' https://generativelanguage.googleapis.com https://ai.example.org");
  // Other directives are untouched.
  assert.match(csp, /script-src 'self' 'wasm-unsafe-eval'/);
  assert.equal(withConnectOrigin(out, 'https://ai.example.org'), out, 'idempotent');
});

test('only exact https origins (http for localhost)', () => {
  assert.equal(exactOrigin('https://ai.example.org'), 'https://ai.example.org');
  assert.equal(exactOrigin('https://ai.example.org:8443'), 'https://ai.example.org:8443');
  assert.equal(exactOrigin('http://localhost:8790'), 'http://localhost:8790');
  for (const bad of ['http://ai.example.org', 'https://*.example.org', 'https://ai.example.org/v1', 'https://u:p@ai.example.org', 'not a url']) {
    assert.throws(() => exactOrigin(bad), bad);
  }
});
