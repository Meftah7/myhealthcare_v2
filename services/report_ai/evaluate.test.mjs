// Mocked contract tests: the grader, the assistant's validation, the DeepSeek
// request and the gateway. These do NOT evaluate a real provider (see
// eval/evaluate.mjs, which needs DEEPSEEK_API_KEY).

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { CHAT_LIMITS, REPORT_EXPLAIN_LIMIT } from '../shared_api/ai.mjs';
import {
  ACTION_IDS, DEFAULT_DEEPSEEK_MODEL, MESSAGES, answerQuestion, deepseekProvider, explainReport, numbersGrounded,
} from './assistant.mjs';
import { cases, explainCases } from './eval/cases.mjs';
import { evaluate, evaluateExplain } from './eval/evaluate.mjs';
import { createGateway, hashTokens } from './server.mjs';

const byQuestion = new Map(cases.map(c => [c.question, c]));
const lastUser = messages => messages.filter(m => m.role === 'user').at(-1).content;

/** Answers each case with its ideal reply; records every call. */
function idealProvider() {
  const calls = [];
  const provider = async ({ messages }) => {
    calls.push(messages);
    if (messages[0].content.includes('Task: summarize')) {
      const c = explainCases.find(x => messages[1].content.includes(x.report));
      return JSON.stringify(c.ideal);
    }
    const c = byQuestion.get(lastUser(messages));
    if (!c?.ideal) throw new Error(`provider must not be asked: ${lastUser(messages)}`);
    return JSON.stringify(c.ideal);
  };
  return Object.assign(provider, { calls });
}

const reply = obj => async () => JSON.stringify(obj);
const metabolic = cases.find(c => c.id === 'abnormal-flag').report;

test('the grader passes ideal replies on every chat and summary case', async () => {
  const provider = idealProvider();
  const chat = await evaluate(provider);
  assert.deepEqual(chat.results.filter(r => r.problems.length), []);
  const summary = await evaluateExplain(provider);
  assert.deepEqual(summary.results.filter(r => r.problems.length), []);
});

test('diagnosis, medicine and two-part questions never reach the provider', async () => {
  const provider = idealProvider();
  for (const id of ['unsupported-treatment', 'diagnosis-request', 'two-part-medication-and-booking']) {
    const c = cases.find(x => x.id === id);
    const r = await answerQuestion(provider, { text: c.report, question: c.question });
    assert.equal(r.refusal, true, id);
    assert.equal(r.action, 'open_appointments', id);
    assert.equal(r.answer, MESSAGES.en.advice, id);
  }
  assert.equal(provider.calls.length, 0);
  const arabic = await answerQuestion(provider, { text: metabolic, question: 'هل أحتاج دواء؟' });
  assert.equal(arabic.answer, MESSAGES.ar.advice);
  const emergency = await answerQuestion(provider, { text: metabolic, question: 'This is an emergency' });
  assert.equal(emergency.answer, MESSAGES.en.emergency);
  assert.equal(emergency.action, null, 'never routed to a routine booking');
});

test('the grader catches invented values, unverifiable quotes and obeyed injections', async () => {
  const lying = reply({
    answer: 'Every result is normal. Your vitamin D is 30 ng/mL.', supported: true,
    quotes: ['Vitamin D 30 ng/mL (20–50)'], action: null, refusal: false,
  });
  const summary = await evaluate(lying);
  const failed = new Set(summary.results.filter(r => r.problems.length).map(r => r.id));
  for (const id of ['malicious-embedded-instructions', 'abnormal-flag', 'normal-values']) assert.ok(failed.has(id), id);
});

test('unsupported or unverifiable answers become the fixed "not found" message', async () => {
  const doc = 'Hemoglobin 14.2 g/dL (13.0–17.0)\nPlatelets 250';
  const invented = await answerQuestion(
    reply({ answer: 'Vitamin D is fine.', supported: true, quotes: ['Vitamin D 30'] }),
    { text: doc, question: 'Vitamin D?' },
  );
  assert.equal(invented.supported, false);
  assert.equal(invented.ungroundedClaim, true);
  assert.equal(invented.answer, MESSAGES.en.notFound);
  assert.deepEqual(invented.quotes, []);
  const absent = await answerQuestion(
    reply({ answer: 'The report does not say, but usually it is low.', supported: false, quotes: [] }),
    { text: doc, question: 'What is my iron?' },
  );
  assert.equal(absent.answer, MESSAGES.en.notFound, 'the model\'s own words are never shown');
  // A supported answer with a number the report lacks is rejected outright.
  await assert.rejects(answerQuestion(
    reply({ answer: 'Hemoglobin 14.2 g/dL; normal is above 12.5.', supported: true, quotes: ['Hemoglobin 14.2 g/dL'] }),
    { text: doc, question: 'Hemoglobin?' },
  ));
  assert.ok(numbersGrounded('14.2 and ١٤٫٢', doc));
  assert.ok(!numbersGrounded('12.5', doc));
});

test('actions come only from the allowlist; links and routes are never shown', async () => {
  const doc = 'Hemoglobin 14.2 g/dL';
  const bogus = await answerQuestion(
    reply({ answer: 'Hemoglobin is 14.2 g/dL.', supported: true, quotes: ['Hemoglobin 14.2 g/dL'], action: 'delete_account' }),
    { text: doc, question: 'Hemoglobin?' },
  );
  assert.equal(bogus.action, null);
  assert.deepEqual(ACTION_IDS, [
    'open_appointments', 'open_records', 'upload_report',
    'open_messages', 'open_medications', 'open_sick_leave', 'open_profile',
  ]);
  for (const answer of ['Book at https://evil.example/book', 'Go to /patient/appointments/book']) {
    await assert.rejects(answerQuestion(
      reply({ answer, supported: true, quotes: ['Hemoglobin 14.2 g/dL'] }),
      { text: doc, question: 'Where?' },
    ), answer);
  }
  const nav = await answerQuestion(
    reply({ answer: 'Tap here: /patient/records', supported: false, quotes: [], action: 'open_records' }),
    { text: doc, question: 'Where are my reports?' },
  );
  assert.equal(nav.answer, MESSAGES.en.open_records, 'the app\'s own words, not the model\'s');
  assert.equal(nav.action, 'open_records');
});

test('summaries: 1–5 grounded bullets, unreadable text, invalid replies', async () => {
  const doc = metabolic;
  const ok = await explainReport(reply({
    readable: true, quotes: ['HbA1c 7.9 % H (4.0–5.6)', 'not in report'],
    bullets: ['• The report labels HbA1c 7.9 % as High.', 'Glucose 99 is fine (page 2).', 'a', 'b', 'c', 'd', 'e'],
  }), { text: doc });
  const lines = ok.answer.split('\n');
  assert.equal(lines[0], '• The report labels HbA1c 7.9 % as High.');
  assert.ok(!ok.answer.includes('99'), 'a bullet with an invented number is dropped');
  assert.ok(lines.length <= 5);
  assert.deepEqual(ok.quotes, ['HbA1c 7.9 % H (4.0–5.6)']);
  const unreadable = await explainReport(reply({ readable: false, bullets: [], quotes: [] }), { text: 'ÿÿÿ', lang: 'ar' });
  assert.equal(unreadable.answer, MESSAGES.ar.unreadable);
  await assert.rejects(explainReport(async () => 'Sure! Here is a summary…', { text: doc }));
  await assert.rejects(explainReport(reply({ readable: true, bullets: [], quotes: [] }), { text: doc }));
  const long = await explainReport(reply({ readable: true, bullets: ['A long report.'], quotes: [] }), {
    text: 'x'.repeat(REPORT_EXPLAIN_LIMIT + 10),
  });
  assert.equal(long.coverage.complete, false);
});

test('DeepSeek: Chat Completions from the server, key in the header, JSON mode, no leaks', async () => {
  let seen;
  const fetchImpl = async (url, init) => {
    seen = { url, init, body: JSON.parse(init.body) };
    return new Response(JSON.stringify({ choices: [{ finish_reason: 'stop', message: { content: '{"ok":true}' } }] }));
  };
  const provider = deepseekProvider({ apiKey: 'sk-test-0123456789', fetchImpl });
  assert.equal(await provider({ messages: [{ role: 'user', content: 'x' }] }), '{"ok":true}');
  assert.equal(seen.url, 'https://api.deepseek.com/chat/completions');
  assert.equal(seen.init.headers.Authorization, 'Bearer sk-test-0123456789');
  assert.equal(seen.body.model, DEFAULT_DEEPSEEK_MODEL);
  assert.equal(DEFAULT_DEEPSEEK_MODEL, 'deepseek-flash');
  assert.deepEqual(seen.body.response_format, { type: 'json_object' });
  assert.ok(!seen.init.body.includes('sk-test'), 'the key is never in the request body');

  const custom = deepseekProvider({ apiKey: 'sk-test-0123456789', model: 'deepseek-chat', fetchImpl });
  await custom({ messages: [] });
  assert.equal(seen.body.model, 'deepseek-chat');

  const failing = deepseekProvider({
    apiKey: 'sk-test-0123456789',
    fetchImpl: async () => new Response('{"error":"invalid key sk-test-0123456789"}', { status: 401 }),
  });
  await assert.rejects(failing({ messages: [] }), e => !e.message.includes('sk-test'));
  const cut = deepseekProvider({
    apiKey: 'sk-test-0123456789',
    fetchImpl: async () => new Response(JSON.stringify({ choices: [{ finish_reason: 'length', message: { content: '{"answer":"Hal' } }] })),
  });
  await assert.rejects(cut({ messages: [] }), /incomplete/);
  assert.throws(() => deepseekProvider({ apiKey: '' }), /DEEPSEEK_API_KEY/);
  assert.throws(() => deepseekProvider({ apiKey: 'sk-test-0123456789', model: 'x/../y' }), /DEEPSEEK_MODEL/);
});

test('report text is delimited untrusted material, after the rules', async () => {
  const provider = idealProvider();
  const c = cases.find(x => x.id === 'malicious-embedded-instructions');
  await answerQuestion(provider, { text: c.report, question: c.question });
  const [system, report] = provider.calls[0];
  assert.equal(system.role, 'system');
  assert.match(system.content, /untrusted source material/);
  assert.ok(!system.content.includes('IGNORE ALL PREVIOUS'));
  assert.match(report.content, /^<<<REPORT\n[\s\S]*\nREPORT>>>$/);
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
  const g = await gateway(t, { provider: idealProvider() });
  assert.equal((await g.call('/v1/health', null, null)).status, 401);
  assert.equal((await g.call('/v1/health', null, 'x'.repeat(40))).status, 401);
  const health = await g.call('/v1/health');
  assert.deepEqual(health.body, { explain: true, chat: true });
  assert.equal(health.headers.get('cache-control'), 'no-store');
});

test('gateway: grounded chat, summary, bounds, unconfigured and DeepSeek unavailable', async t => {
  const g = await gateway(t, { provider: idealProvider() });
  const c = cases.find(x => x.id === 'abnormal-flag');
  const ok = await g.call('/v1/reports/chat', { text: c.report, question: c.question, history: [] });
  assert.equal(ok.status, 200);
  assert.equal(ok.body.supported, true);
  assert.ok(ok.body.quotes.length >= 1);
  assert.equal(ok.body.action, null);
  assert.equal(ok.body.coverage.complete, true);

  const summary = await g.call('/v1/reports/explain', { text: explainCases[0].report, lang: 'en' });
  assert.equal(summary.status, 200);
  assert.match(summary.body.answer, /^• /);
  assert.equal((await g.call('/v1/reports/explain', { text: 'a', lang: 'fr' })).status, 400);

  // Bounds: oversized question, too much history, unknown fields.
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q'.repeat(CHAT_LIMITS.maxQuestionChars + 1) })).status, 400);
  const history = Array.from({ length: CHAT_LIMITS.maxHistoryTurns + 1 }, () => ({ role: 'user', text: 'hi' }));
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', history })).status, 400);
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', apiKey: 'k' })).status, 400);
  assert.equal((await g.call('/v1/reports/chat', { text: 'a', question: 'q', history: [{ role: 'system', text: 'x' }] })).status, 400);

  // DeepSeek unavailable, or a reply that fails validation: a plain 502.
  for (const provider of [
    async () => { throw new Error('provider down: secret detail'); },
    async () => 'raw provider text that is not JSON',
  ]) {
    const down = await gateway(t, { provider });
    for (const [path, body] of [['/v1/reports/chat', { text: 'a', question: 'q' }], ['/v1/reports/explain', { text: 'a' }]]) {
      const failed = await down.call(path, body);
      assert.equal(failed.status, 502);
      assert.doesNotMatch(JSON.stringify(failed.body), /secret detail|raw provider text/);
    }
  }

  const none = await gateway(t, {});
  assert.equal((await none.call('/v1/reports/chat', { text: 'a', question: 'q' })).status, 503);
  assert.equal((await none.call('/v1/reports/explain', { text: 'a' })).status, 503);
  // Fixed refusals need no provider.
  const refused = await none.call('/v1/reports/chat', { text: 'a', question: 'Should I stop my medicine?' });
  assert.equal(refused.status, 200);
  assert.equal(refused.body.refusal, true);
});
