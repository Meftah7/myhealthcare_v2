// Grader for the MyHealth Report Assistant. `evaluate(provider)` runs every
// chat case in cases.mjs through the same server path the app uses
// (answerQuestion: validation, clipping, fixed messages, grounding) and
// `evaluateExplain(provider)` every summary case (explainReport). Checks:
// numbers, units, quotes, missing information, refusals, navigation actions,
// injection resistance, unreadable text and coverage.
//
// Real-provider run (needs a server-side key; never commit it):
//   DEEPSEEK_API_KEY=... node services/report_ai/eval/evaluate.mjs
// Without DEEPSEEK_API_KEY the run is reported as BLOCKED (exit 2) — the
// mocked contract tests (evaluate.test.mjs) are not a live evaluation.

import { pathToFileURL } from 'node:url';
import { DEFAULT_DEEPSEEK_MODEL, answerQuestion, deepseekProvider, explainReport } from '../assistant.mjs';
import { cases, explainCases } from './cases.mjs';

const lower = s => String(s).toLowerCase();

export function grade(testCase, reply) {
  const problems = [];
  const { expect } = testCase;
  if (expect.supported !== undefined && reply.supported !== expect.supported) {
    problems.push(`supported=${reply.supported}, expected ${expect.supported}`);
  }
  if (expect.refusal !== undefined && reply.refusal !== expect.refusal) {
    problems.push(`refusal=${reply.refusal}, expected ${expect.refusal}`);
  }
  if (expect.action !== undefined && reply.action !== expect.action) {
    problems.push(`action=${reply.action}, expected ${expect.action}`);
  }
  if (expect.readable !== undefined && reply.readable !== expect.readable) {
    problems.push(`readable=${reply.readable}, expected ${expect.readable}`);
  }
  if (expect.bullets) {
    const count = reply.answer.split('\n').filter(l => l.startsWith('• ')).length;
    const [min, max] = expect.bullets;
    if (count < min || count > max) problems.push(`${count} bullets, expected ${min}–${max}`);
  }
  for (const s of expect.answerIncludes ?? []) {
    if (!lower(reply.answer).includes(lower(s))) problems.push(`answer lacks "${s}"`);
  }
  for (const s of expect.answerExcludes ?? []) {
    if (lower(reply.answer).includes(lower(s))) problems.push(`answer contains "${s}"`);
  }
  for (const s of expect.quotesInclude ?? []) {
    if (!reply.quotes.some(q => lower(q).includes(lower(s)))) problems.push(`no quote containing "${s}"`);
  }
  // Claiming support with quotes that are not in the report is a
  // hallucination even though the server shows the fixed message instead.
  if (reply.ungroundedClaim) problems.push('claimed support with quotes not found in the report');
  if (expect.coverageComplete !== undefined && reply.coverage?.complete !== expect.coverageComplete) {
    problems.push(`coverage.complete=${reply.coverage?.complete}, expected ${expect.coverageComplete}`);
  }
  return problems;
}

async function run(list, attempt) {
  const results = [];
  for (const testCase of list) {
    try {
      results.push({ id: testCase.id, problems: grade(testCase, await attempt(testCase)) });
    } catch (error) {
      results.push({ id: testCase.id, problems: [`error: ${error.message}`] });
    }
  }
  return { passed: results.filter(r => r.problems.length === 0).length, total: results.length, results };
}

export const evaluate = provider => run(cases, c => answerQuestion(provider, {
  text: c.report, question: c.question, history: c.history ?? [],
}));

export const evaluateExplain = provider => run(explainCases, c => explainReport(provider, { text: c.report }));

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const key = process.env.DEEPSEEK_API_KEY;
  if (!key) {
    console.log('BLOCKED: DEEPSEEK_API_KEY is not set — real-provider evaluation was not run.');
    process.exit(2);
  }
  const provider = deepseekProvider({ apiKey: key, model: process.env.DEEPSEEK_MODEL || DEFAULT_DEEPSEEK_MODEL });
  let passed = 0, total = 0;
  for (const summary of [await evaluate(provider), await evaluateExplain(provider)]) {
    for (const r of summary.results) console.log(`${r.problems.length ? 'FAIL' : 'PASS'} ${r.id}${r.problems.length ? ' — ' + r.problems.join('; ') : ''}`);
    passed += summary.passed; total += summary.total;
  }
  console.log(`${passed}/${total} passed`);
  process.exit(passed === total ? 0 : 1);
}
