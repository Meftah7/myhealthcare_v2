// Mocked contract tests: the grader, the grounding check and the gateway.
// These do NOT evaluate a real provider (see eval/evaluate.mjs).

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { CHAT_LIMITS, REPORT_EXPLAIN_LIMIT, parseGroundedAnswer } from '../shared_api/ai.mjs';
import { cases } from './eval/cases.mjs';
import { evaluate } from './eval/evaluate.mjs';
import { createGateway, hashTokens } from './server.mjs';

const byQuestion = new Map(cases.map(c => [c.question, c]));

/** A provider that answers each case with its ideal grounded reply. */
const idealProvider = async ({ question }) => JSON.stringify(byQuestion.get(question).ideal);

test('the grader passes ideal grounded answers on every case', async () => {
  const summary = await evaluate(idealProvider);
  assert.deepEqual(summary.results.filter(r => r.problems.length), []);
  assert.equal(summary.passed, cases.length);
});

test('the grader catches invented values, unverifiable quotes and obeyed injections', async () => {
  const lying = async ({ question }) => JSON.stringify({
    answer: 'Every result is normal. Your vitamin D is 30 ng/mL.', supported: true,
    quotes: ['Vitamin D 30 ng/mL (20–50)'],
  });
  const summary = await evaluate(lying);
  const failed = new Set(summary.results.filter(r => r.problems.length).map(r => r.id));
  for (const id of ['missing-information', 'malicious-embedded-instructions', 'abnormal-flag', 'long-report-partial-coverage']) {
    assert.ok(failed.has(id), id);
  }
});

test('grounding: quotes must be verbatim report text; unsupported claims are downgraded', () => {
  const doc = 'Hemoglobin 14.2 g/dL (13.0–17.0)\nPlatelets 250';
  const ok = parseGroundedAnswer('{"answer":"14.2","supported":true,"quotes":["hemoglobin  14.2 g/dL"]}', doc);
  assert.equal(ok.supported, true);
  assert.deepEqual(ok.quotes, ['hemoglobin  14.2 g/dL']);
  const invented = parseGroundedAnswer('{"answer":"Vitamin D is fine","supported":true,"quotes":["Vitamin D 30"]}', doc);
  assert.equal(invented.supported, false);
  assert.equal(invented.ungroundedClaim, true);
  assert.deepEqual(invented.quotes, []);
  const fenced = parseGroundedAnswer('```json\n{"answer":"No.","supported":false,"quotes":[]}\n```', doc);
  assert.equal(fenced.supported, false);
  assert.throws(() => parseGroundedAnswer('not json', doc));
  assert.throws(() => parseGroundedAnswer('{"supported":true}', doc));
});

async function gateway(t, options = {}) {
  const token = randomBytes(24).toString('base64url');
  const server = createGateway({ tokenHashes: hashTokens(token), origins: ['http://localhost:8080'], ...options });
  await new Promise(r => server.listen(0, '127.0.0.1', r));
  t.after(() => new Promise(r => { server.close(r); server.closeAllConnections(); }));
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (path, body, auth = token) => {
    const response = await fetch(base + path, {
      method: body ? 'POST' : 'GET',
      headers: { ...(auth ? { Authorization: `Bearer ${auth}` } : {}), ...(body ? { 'Content-Type': 'application/json' } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    return { status: response.status, body: await response.json(), headers: response.headers };
  };
  return { call, token };
}

test('gateway: client token required; health reports configuration only', async t => {
  const g = await gateway(t, { chat: idealProvider });
  assert.equal((await g.call('/v1/health', null, null)).status, 401);
  assert.equal((await g.call('/v1/health', null, 'x'.repeat(40))).status, 401);
  const health = await g.call('/v1/health');
  assert.deepEqual(health.body, { explain: false, chat: true });
  assert.equal(health.headers.get('cache-control'), 'no-store');
});

test('gateway: grounded chat, bounds, unconfigured and provider failure', async t => {
  const g = await gateway(t, { chat: idealProvider, explainer: async () => 'Plain explanation.' });
  const c = cases.find(x => x.id === 'abnormal-flag');
  const ok = await g.call('/v1/reports/chat', { text: c.report, question: c.question, history: [] });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.draft, true);
  assert.equal(ok.body.supported, true);
  assert.ok(ok.body.quotes.length >= 1);
  assert.equal(ok.body.coverage.complete, true);

  const explained = await g.call('/v1/reports/explain', { text: 'x'.repeat(REPORT_EXPLAIN_LIMIT + 10) });
  assert.equal(explained.status, 200);
  assert.equal(explained.body.coverage.complete, false);

  // Bounds: oversized question, too much history, unknown fields.
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q'.repeat(CHAT_LIMITS.maxQuestionChars + 1) })).status, 400);
  const history = Array.from({ length: CHAT_LIMITS.maxHistoryTurns + 1 }, () => ({ role: 'user', text: 'hi' }));
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', history })).status, 400);
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', apiKey: 'k' })).status, 400);
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', history: [{ role: 'system', text: 'x' }] })).status, 400);

  const down = await gateway(t, { chat: async () => { throw new Error('provider down: secret detail'); } });
  const failed = await down.call('/v1/reports/chat', { text: 'a', question: 'q' });
  assert.equal(failed.status, 502);
  assert.doesNotMatch(JSON.stringify(failed.body), /secret detail/);

  const none = await gateway(t, {});
  assert.equal((await none.call('/v1/reports/chat', { text: 'a', question: 'q' })).status, 503);
  assert.equal((await none.call('/v1/reports/explain', { text: 'a' })).status, 503);
});
