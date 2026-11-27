// Grader for the MyHealth assistant. Runs every case in cases.mjs through
// the same server code the gateway uses — answerQuestion (factual lookup),
// answerChat (ordinary conversation) and summarizeDocument — and checks
// values, units, quotes, missing information, fixed medical refusals and
// their actions, emergencies, injection resistance, unreadable text and
// coverage.
//
// Real-provider run (needs a server-side key; never commit it):
//   DEEPSEEK_API_KEY=... node services/report_ai/eval/evaluate.mjs
// Without DEEPSEEK_API_KEY the run is reported as BLOCKED (exit 2) — the
// mocked contract tests (evaluate.test.mjs) are not a live evaluation.

import { pathToFileURL } from 'node:url';
import {
  DEFAULT_DEEPSEEK_MODEL, answerChat, answerQuestion, deepseekProvider, summarizeDocument,
} from '../assistant.mjs';
import { cases, chatCases, summaryCases } from './cases.mjs';

const lower = s => String(s).toLowerCase();
const includes = (problems, text, list = [], label = 'text') => {
  for (const s of list) if (!lower(text).includes(lower(s))) problems.push(`${label} lacks "${s}"`);
};
const excludes = (problems, text, list = [], label = 'text') => {
  for (const s of list) if (lower(text).includes(lower(s))) problems.push(`${label} contains "${s}"`);
};
const same = (problems, name, got, want) => {
  if (want !== undefined && JSON.stringify(got) !== JSON.stringify(want)) {
    problems.push(`${name}=${JSON.stringify(got)}, expected ${JSON.stringify(want)}`);
  }
};

export function grade(testCase, reply) {
  const problems = [];
  const { expect } = testCase;
  same(problems, 'supported', reply.supported, expect.supported);
  same(problems, 'refusal', reply.refusal, expect.refusal);
  same(problems, 'medical', reply.medical, expect.medical);
  same(problems, 'action', reply.action, expect.action);
  same(problems, 'actions', reply.actions, expect.actions);
  includes(problems, reply.answer, expect.answerIncludes, 'answer');
  excludes(problems, reply.answer, expect.answerExcludes, 'answer');
  for (const s of expect.quotesInclude ?? []) {
    if (!reply.quotes.some(q => lower(q).includes(lower(s)))) problems.push(`no quote containing "${s}"`);
  }
  // Claiming support with quotes that are not in the document is a
  // hallucination even though the gateway shows the fixed message instead.
  if (reply.ungroundedClaim) problems.push('claimed support with quotes not found in the document');
  if (expect.coverageComplete !== undefined && reply.coverage?.complete !== expect.coverageComplete) {
    problems.push(`coverage.complete=${reply.coverage?.complete}, expected ${expect.coverageComplete}`);
  }
  return problems;
}

export function gradeChat(testCase, reply) {
  const problems = [];
  const { expect } = testCase;
  same(problems, 'medical', reply.medical, expect.medical);
  same(problems, 'emergency', reply.emergency, expect.emergency);
  same(problems, 'action', reply.action, expect.action);
  same(problems, 'actions', reply.actions, expect.actions);
  includes(problems, reply.reply, expect.replyIncludes, 'reply');
  return problems;
}

export function gradeSummary(testCase, reply) {
  const problems = [];
  const { expect } = testCase;
  same(problems, 'readable', reply.readable, expect.readable);
  if (expect.points) {
    const [min, max] = expect.points;
    if (reply.points.length < min || reply.points.length > max) problems.push(`${reply.points.length} points, expected ${min}–${max}`);
  }
  const text = [reply.overview, ...reply.points].join('\n');
  includes(problems, text, expect.textIncludes);
  excludes(problems, text, expect.textExcludes);
  for (const s of expect.quotesInclude ?? []) {
    if (!reply.quotes.some(q => lower(q).includes(lower(s)))) problems.push(`no quote containing "${s}"`);
  }
  same(problems, 'coverage.complete', reply.coverage?.complete, expect.complete);
  return problems;
}

async function run(list, attempt, check) {
  const results = [];
  for (const testCase of list) {
    try {
      results.push({ id: testCase.id, problems: check(testCase, await attempt(testCase)) });
    } catch (error) {
      results.push({ id: testCase.id, problems: [`error: ${error.message}`] });
    }
  }
  return { passed: results.filter(r => r.problems.length === 0).length, total: results.length, results };
}

export const evaluate = provider => run(cases, c => answerQuestion(provider, {
  text: c.report, question: c.question, history: c.history ?? [],
}), grade);

export const evaluateChat = provider => run(chatCases, c => answerChat(provider, {
  message: c.message, history: c.history ?? [],
}), gradeChat);

export const evaluateSummaries = provider => run(summaryCases, c => summarizeDocument(provider, {
  text: c.text, lang: 'en',
}), gradeSummary);

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const key = process.env.DEEPSEEK_API_KEY;
  if (!key) {
    console.log('BLOCKED: DEEPSEEK_API_KEY is not set — real-provider evaluation was not run.');
    process.exit(2);
  }
  const provider = deepseekProvider({ apiKey: key, model: process.env.DEEPSEEK_MODEL || DEFAULT_DEEPSEEK_MODEL });
  let passed = 0, total = 0;
  for (const summary of [await evaluate(provider), await evaluateChat(provider), await evaluateSummaries(provider)]) {
    for (const r of summary.results) console.log(`${r.problems.length ? 'FAIL' : 'PASS'} ${r.id}${r.problems.length ? ' — ' + r.problems.join('; ') : ''}`);
    passed += summary.passed; total += summary.total;
  }
  console.log(`${passed}/${total} passed`);
  process.exit(passed === total ? 0 : 1);
}
