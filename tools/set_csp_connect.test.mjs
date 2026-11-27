import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { exactOrigin, withConnectOrigin } from './set_csp_connect.mjs';
import { randomBytes } from 'node:crypto';
import { gatewayEnvironment, pageGatewayConfig } from '../services/report_ai/config.mjs';
import { checkReportAiGateway } from './check_report_ai_deployment.mjs';

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
  for (const bad of ['http://ai.example.org', 'https://*.example.org', 'https://ai.example.org/v1', 'https://ai.example.org/', 'https://u:p@ai.example.org', 'not a url']) {
    assert.throws(() => exactOrigin(bad), bad);
  }
});

test('Pages deployments default to live and reject missing or sample settings', () => {
  const token = randomBytes(32).toString('base64url');
  const env = { REPORT_AI_ORIGIN: 'https://ai.myhealth-gateway.org', REPORT_AI_CLIENT_TOKEN: token };
  assert.deepEqual(pageGatewayConfig(env), { mode: 'live', origin: env.REPORT_AI_ORIGIN, token });
  assert.deepEqual(pageGatewayConfig({ REPORT_AI_MODE: 'offline' }), { mode: 'offline' });
  assert.throws(() => pageGatewayConfig({}), /REPORT_AI_ORIGIN/);
  assert.throws(() => pageGatewayConfig({ ...env, REPORT_AI_MODE: 'disabled' }), /REPORT_AI_MODE/);
  for (const origin of ['https://ai.example.org', 'http://127.0.0.1:8790', 'https://ai.myhealth-gateway.org/']) {
    assert.throws(() => pageGatewayConfig({ ...env, REPORT_AI_ORIGIN: origin }), /REPORT_AI_ORIGIN/);
  }
  for (const invalid of ['', 'word', 'A'.repeat(40), 'x'.repeat(129), 'replace_me_' + token, token + '=']) {
    assert.throws(() => pageGatewayConfig({ ...env, REPORT_AI_CLIENT_TOKEN: invalid }), /REPORT_AI_CLIENT_TOKEN/);
  }
});

test('gateway startup validates accepted tokens, origin, port and provider setting', () => {
  const token = randomBytes(32).toString('base64url');
  const env = { REPORT_AI_CLIENT_TOKENS: token, REPORT_AI_ORIGINS: 'https://meftah7.github.io' };
  assert.equal(gatewayEnvironment(env).port, 8790);
  assert.throws(() => gatewayEnvironment({ ...env, PORT: '0' }), /PORT/);
  assert.throws(() => gatewayEnvironment({ ...env, REPORT_AI_ORIGINS: 'https://meftah7.github.io/myhealthcare_v2' }), /REPORT_AI_ORIGINS/);
  assert.throws(() => gatewayEnvironment({ ...env, REPORT_AI_CLIENT_TOKENS: 'short' }), /REPORT_AI_CLIENT_TOKENS/);
  assert.throws(() => gatewayEnvironment({ ...env, REPORT_AI_REQUIRE_PROVIDER: 'true' }), /DEEPSEEK_API_KEY/);
  assert.throws(() => gatewayEnvironment({ ...env, DEEPSEEK_API_KEY: '<your-deepseek-api-key>' }), /DEEPSEEK_API_KEY/);
});

test('deployment check verifies preflight, authenticated readiness and both synthetic responses', async () => {
  const origin = 'https://ai.myhealth-gateway.org';
  const token = randomBytes(32).toString('base64url');
  const browserOrigin = 'https://meftah7.github.io';
  const allow = { 'Access-Control-Allow-Origin': browserOrigin };
  const health = { ready: true, chat: true, summarize: true, provider: 'deepseek' };
  const paths = [];
  await checkReportAiGateway({
    origin, token, smoke: true,
    fetchImpl: async (url, request) => {
      const path = new URL(url).pathname;
      paths.push([request.method, path]);
      assert.equal(request.headers.Origin, browserOrigin);
      assert.equal(request.redirect, 'error');
      if (request.method === 'OPTIONS') {
        assert.equal(request.headers['Access-Control-Request-Headers'], 'authorization,content-type,idempotency-key');
        return new Response(null, { status: 204, headers: {
          ...allow, 'Access-Control-Allow-Methods': 'GET, POST',
          'Access-Control-Allow-Headers': 'Authorization, Content-Type, Idempotency-Key',
        } });
      }
      assert.equal(request.headers.Authorization, 'Bearer ' + token);
      if (path === '/v1/health') return Response.json(health, { headers: allow });
      if (path === '/v1/chat') {
        assert.match(JSON.parse(request.body).message, /change the language/);
        return Response.json({ reply: 'Open Settings to change the language.', medical: false, emergency: false }, { headers: allow });
      }
      assert.match(JSON.parse(request.body).text, /^Synthetic training handout/);
      return Response.json({ readable: true, partial: false, overview: 'The library opens on Monday.', points: [] }, { headers: allow });
    },
  });
  assert.deepEqual(paths, [
    ['OPTIONS', '/v1/documents/summarize'], ['GET', '/v1/health'],
    ['POST', '/v1/chat'], ['POST', '/v1/documents/summarize'],
  ]);
  await assert.rejects(checkReportAiGateway({
    origin, token,
    fetchImpl: async () => new Response(null, { status: 204, headers: { 'Access-Control-Allow-Origin': '*' } }),
  }), /CORS preflight failed/);
});

test('deployment check waits for a cold gateway and stops on rejected credentials', async () => {
  const browserOrigin = 'https://meftah7.github.io';
  const headers = {
    'Access-Control-Allow-Origin': browserOrigin,
    'Access-Control-Allow-Methods': 'GET, POST',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Idempotency-Key',
  };
  let preflights = 0;
  let healthChecks = 0;
  let retries = 0;
  await assert.rejects(checkReportAiGateway({
    origin: 'https://ai.myhealth-gateway.org',
    token: randomBytes(32).toString('base64url'),
    waitForRetry: async () => { retries++; },
    fetchImpl: async (_url, request) => {
      if (request.method === 'OPTIONS') {
        preflights++;
        if (preflights === 1) throw new DOMException('Timed out', 'TimeoutError');
        if (preflights === 2) return new Response('Starting', { status: 503 });
        return new Response(null, { status: 204, headers });
      }
      healthChecks++;
      return new Response(null, { status: 401, headers });
    },
  }), /rejected REPORT_AI_CLIENT_TOKEN/);
  assert.equal(preflights, 3);
  assert.equal(healthChecks, 1);
  assert.equal(retries, 2);
});
