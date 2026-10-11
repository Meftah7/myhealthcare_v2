// Grader for the grounded report chat. `evaluate(provider)` runs every case
// in cases.mjs through the same server path the app uses
// (answerReportQuestion: validation, clipping, grounding) and checks numbers,
// units, quotes, unsupported questions, injection resistance and coverage.
//
// Real-provider run (needs a server-side key; never commit it):
//   MYHEALTH_AI_KEY=... node services/report_ai/eval/evaluate.mjs
// Without MYHEALTH_AI_KEY the run is reported as BLOCKED (exit 2) — mocked
// contract tests (evaluate.test.mjs) are not a live evaluation.

import { pathToFileURL } from 'node:url';
import { answerReportQuestion, geminiReportChat } from '../../shared_api/ai.mjs';
import { cases } from './cases.mjs';

const lower = s => String(s).toLowerCase();

export function grade(testCase, reply) {
  const problems = [];
  const { expect } = testCase;
  if (expect.supported !== undefined && reply.supported !== expect.supported) {
    problems.push(`supported=${reply.supported}, expected ${expect.supported}`);
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
  // hallucination even though the server shows the answer as unsupported.
  if (reply.ungroundedClaim) problems.push('claimed support with quotes not found in the report');
  if (expect.coverageComplete !== undefined && reply.coverage?.complete !== expect.coverageComplete) {
    problems.push(`coverage.complete=${reply.coverage?.complete}, expected ${expect.coverageComplete}`);
  }
  return problems;
}

export async function evaluate(provider) {
  const results = [];
  for (const testCase of cases) {
    try {
      const reply = await answerReportQuestion(provider, {
        text: testCase.report, question: testCase.question, history: testCase.history ?? [],
      });
      results.push({ id: testCase.id, problems: grade(testCase, reply) });
    } catch (error) {
      results.push({ id: testCase.id, problems: [`error: ${error.message}`] });
    }
  }
  return { passed: results.filter(r => r.problems.length === 0).length, total: results.length, results };
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const key = process.env.MYHEALTH_AI_KEY;
  if (!key) {
    console.log('BLOCKED: MYHEALTH_AI_KEY is not set — real-provider evaluation was not run.');
    process.exit(2);
  }
  const summary = await evaluate(geminiReportChat({ apiKey: key, model: process.env.MYHEALTH_AI_MODEL || undefined }));
  for (const r of summary.results) console.log(`${r.problems.length ? 'FAIL' : 'PASS'} ${r.id}${r.problems.length ? ' — ' + r.problems.join('; ') : ''}`);
  console.log(`${summary.passed}/${summary.total} passed`);
  process.exit(summary.passed === summary.total ? 0 : 1);
}
