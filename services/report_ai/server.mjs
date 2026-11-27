// Report AI gateway for the full (local-Drift) myhealth app.
//
// The local app keeps all clinical data on the device and has no server
// account, so it cannot call the shared API. This gateway is the only place
// the AI provider key lives. The provider is DeepSeek (Chat Completions);
// there is no fallback to another provider.
//
//   GET  /v1/health               readiness: authorized client + provider set
//   POST /v1/chat                 ordinary conversation (no document)
//   POST /v1/documents/summarize  overview + main points of ONE document's
//                                 text (the app reads the file; originals
//                                 never leave the device)
//   POST /v1/reports/chat         factual lookup in that document
//   POST /v1/reports/explain      earlier explain contract (now a summary)
//
// Boundary: the gateway authenticates the client installation (a configured
// client token, compared by hash), not the patient — a token in a public web
// build is not a secret and is not patient authorization. Patient/document
// authorization is enforced by the app before sending. For multi-user server
// data use the shared API's /api/reports/* endpoints.
//
// The medical-question rule is enforced here (assistant.mjs,
// medical_policy.mjs), so callers that bypass the app get the same fixed
// refusals. Nothing here logs documents, questions, replies or credentials.

import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import {
  DEFAULT_DEEPSEEK_MODEL, InvalidReplyError, LIMITS, ProviderError, answerChat, answerQuestion,
  deepseekProvider, explainReport, summarizeDocument,
} from './assistant.mjs';

const MAX_BODY = 192 * 1024;
/** Document text up to LIMITS.summaryTextChars, in UTF-8 (Arabic: 2 bytes). */
const MAX_SUMMARY_BODY = 640 * 1024;
const PER_MINUTE = 30;
const SUMMARIES_PER_MINUTE = 6;
const IDEMPOTENCY_TTL_MS = 10 * 60 * 1000;
const IDEMPOTENCY_MAX = 200;

/** `code` lets the app tell failures apart; `error` is a plain sentence. */
class GatewayError extends Error {
  constructor(status, code, message) { super(message); this.status = status; this.code = code; }
}

const sha256 = value => createHash('sha256').update(value).digest();

/** A provider failure as a gateway error — never the provider's details. */
function providerFailure(error) {
  if (error instanceof ProviderError) {
    switch (error.kind) {
      case 'config': return new GatewayError(503, 'provider_unavailable', 'The AI service is not available right now.');
      case 'rate_limited': return new GatewayError(503, 'provider_busy', 'The AI service is busy. Try again in a minute.');
      case 'timeout': return new GatewayError(504, 'provider_timeout', 'The AI service took too long. Try again.');
      default: return new GatewayError(502, 'provider_failed', 'The AI service could not answer. Try again.');
    }
  }
  if (error instanceof InvalidReplyError) return new GatewayError(502, 'invalid_reply', 'The AI service could not produce a usable answer. Try again.');
  if (/^Invalid /.test(error?.message ?? '')) return new GatewayError(400, 'invalid', error.message);
  return new GatewayError(502, 'provider_failed', 'The AI service could not answer. Try again.');
}

export function createGateway({ tokenHashes, origins = [], provider, now = () => Date.now() }) {
  const hashes = (tokenHashes ?? []).map(h => Buffer.from(h, 'hex'));
  const buckets = new Map();
  const results = new Map(); // idempotency: key -> { at, promise }

  function authorize(req) {
    const raw = req.headers.authorization;
    if (typeof raw !== 'string' || !/^Bearer [A-Za-z0-9_-]{32,128}$/.test(raw)) {
      throw new GatewayError(401, 'unauthorized', 'Client not recognised.');
    }
    const presented = sha256(raw.slice(7));
    const ok = hashes.some(h => h.length === presented.length && timingSafeEqual(h, presented));
    if (!ok) throw new GatewayError(401, 'unauthorized', 'Client not recognised.');
    return presented.toString('hex').slice(0, 16);
  }
  function limit(client, kind = 'all', perMinute = PER_MINUTE) {
    const key = `${client}:${kind}`;
    const time = now(), item = buckets.get(key);
    const next = !item || time - item.at >= 60000 ? { at: time, count: 1 } : { ...item, count: item.count + 1 };
    buckets.set(key, next);
    if (next.count > perMinute) throw new GatewayError(429, 'rate_limited', 'Too many requests. Try again later.');
  }
  async function readJson(req, max = MAX_BODY) {
    if (req.headers['content-type']?.split(';')[0] !== 'application/json') throw new GatewayError(415, 'invalid', 'Use JSON requests.');
    const declared = Number(req.headers['content-length']);
    if (Number.isFinite(declared) && declared > max) throw new GatewayError(413, 'too_large', 'Request too large.');
    const chunks = []; let length = 0;
    for await (const chunk of req) {
      length += chunk.length;
      if (length > max) throw new GatewayError(413, 'too_large', 'Request too large.');
      chunks.push(chunk);
    }
    try { return JSON.parse(Buffer.concat(chunks).toString()); } catch { throw new GatewayError(400, 'invalid', 'Invalid JSON.'); }
  }
  function onlyFields(body, allowed) {
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(k => !allowed.includes(k))) {
      throw new GatewayError(400, 'invalid', 'Invalid request.');
    }
  }
  function requireProvider() {
    if (typeof provider !== 'function') throw new GatewayError(503, 'not_configured', 'The AI service is not configured.');
  }
  /** Runs [work] once per (client, Idempotency-Key) for a while. */
  function once(client, req, work) {
    const key = req.headers['idempotency-key'];
    if (typeof key !== 'string' || !/^[A-Za-z0-9_-]{16,128}$/.test(key)) return work();
    const id = `${client}:${key}`;
    const time = now();
    for (const [k, v] of results) if (time - v.at > IDEMPOTENCY_TTL_MS) results.delete(k);
    const hit = results.get(id);
    if (hit) return hit.promise;
    if (results.size >= IDEMPOTENCY_MAX) results.delete(results.keys().next().value);
    const promise = work();
    results.set(id, { at: time, promise });
    // A failed attempt may be retried with the same key.
    promise.catch(() => results.delete(id));
    return promise;
  }
  async function run(fn) {
    try {
      return await fn();
    } catch (error) {
      if (error instanceof GatewayError) throw error;
      throw providerFailure(error);
    }
  }

  async function dispatch(req, path, signal) {
    const client = authorize(req);
    if (path === '/v1/health' && req.method === 'GET') {
      // Readiness: this client is authorized and a provider is configured.
      // It is not proof that a provider call will succeed.
      const configured = typeof provider === 'function';
      return { ready: configured, chat: configured, summarize: configured, explain: configured, provider: 'deepseek' };
    }
    if (path === '/v1/chat' && req.method === 'POST') {
      const body = await readJson(req);
      onlyFields(body, ['message', 'history']);
      limit(client);
      const result = await run(() => answerChat(provider, body, { signal }));
      if (result === null) requireProvider();
      return result;
    }
    if (path === '/v1/documents/summarize' && req.method === 'POST') {
      const body = await readJson(req, MAX_SUMMARY_BODY);
      onlyFields(body, ['text', 'lang', 'fileName', 'sourceChars', 'extractionComplete']);
      if (typeof body.text !== 'string' || !body.text.trim() || body.text.length > LIMITS.summaryTextChars) {
        throw new GatewayError(400, 'invalid', 'Invalid document text.');
      }
      if (body.lang !== undefined && !['en', 'ar'].includes(body.lang)) throw new GatewayError(400, 'invalid', 'Invalid language.');
      requireProvider();
      return once(client, req, async () => {
        limit(client, 'summary', SUMMARIES_PER_MINUTE);
        return run(() => summarizeDocument(provider, body, { signal }));
      });
    }
    if (path === '/v1/reports/chat' && req.method === 'POST') {
      const body = await readJson(req);
      onlyFields(body, ['text', 'question', 'history']);
      limit(client);
      const result = await run(() => answerQuestion(provider, body, { signal }));
      if (result === null) requireProvider();
      return result;
    }
    if (path === '/v1/reports/explain' && req.method === 'POST') {
      const body = await readJson(req, MAX_SUMMARY_BODY);
      onlyFields(body, ['text', 'lang']);
      if (typeof body.text !== 'string' || !body.text.trim() || body.text.length > 200000) {
        throw new GatewayError(400, 'invalid', 'Invalid report text.');
      }
      if (body.lang !== undefined && !['en', 'ar'].includes(body.lang)) throw new GatewayError(400, 'invalid', 'Invalid language.');
      limit(client, 'summary', SUMMARIES_PER_MINUTE);
      requireProvider();
      return run(() => explainReport(provider, { text: body.text, lang: body.lang ?? 'en' }, { signal }));
    }
    throw new GatewayError(404, 'not_found', 'Endpoint unavailable.');
  }

  const server = createServer(async (req, res) => {
    const headers = {
      'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
    };
    // Stop provider work when the app cancels (closed connection).
    const controller = new AbortController();
    res.on('close', () => { if (!res.writableFinished) controller.abort(); });
    try {
      const origin = req.headers.origin;
      if (origin && !origins.includes(origin)) throw new GatewayError(403, 'origin_not_allowed', 'Origin not allowed.');
      if (origin) Object.assign(headers, { 'Access-Control-Allow-Origin': origin, Vary: 'Origin' });
      if (req.method === 'OPTIONS') {
        res.writeHead(204, { ...headers, 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization,Content-Type,Idempotency-Key',
          'Access-Control-Max-Age': '600' });
        res.end(); return;
      }
      const result = await dispatch(req, new URL(req.url, 'http://localhost').pathname, controller.signal);
      res.writeHead(200, { ...headers, 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result));
    } catch (error) {
      const known = error instanceof GatewayError;
      const status = known ? error.status : 500;
      res.writeHead(status, { ...headers, 'Content-Type': 'application/json' });
      res.end(JSON.stringify(known
        ? { error: error.message, code: error.code }
        : { error: 'Server could not complete the request.', code: 'server_error' }));
    }
  });
  server.requestTimeout = 180000; server.headersTimeout = 15000;
  return server;
}

/** Token hashes for REPORT_AI_CLIENT_TOKENS (comma-separated raw tokens). */
export function hashTokens(raw) {
  return (raw ?? '').split(',').map(t => t.trim()).filter(Boolean).map(t => sha256(t).toString('hex'));
}

// `node services/report_ai/server.mjs` — configuration from the environment
// (a secret store in production; never Git or a client build).
if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const key = process.env.DEEPSEEK_API_KEY;
  const model = process.env.DEEPSEEK_MODEL || DEFAULT_DEEPSEEK_MODEL;
  const tokenHashes = hashTokens(process.env.REPORT_AI_CLIENT_TOKENS);
  if (tokenHashes.length === 0) throw new Error('Set REPORT_AI_CLIENT_TOKENS (32+ character client tokens).');
  const origins = (process.env.REPORT_AI_ORIGINS ?? '').split(',').map(o => o.trim()).filter(Boolean);
  for (const o of origins) {
    // Exact origins only: no wildcards, paths or trailing slashes.
    if (!/^https?:\/\/[A-Za-z0-9.-]+(:\d+)?$/.test(o)) throw new Error(`REPORT_AI_ORIGINS: "${o}" is not an exact origin.`);
  }
  const server = createGateway({
    tokenHashes,
    origins,
    provider: key ? deepseekProvider({ apiKey: key, model }) : undefined,
  });
  const port = Number(process.env.PORT ?? 8790);
  // Loopback by default: put the gateway behind an HTTPS reverse proxy. Set
  // HOST=0.0.0.0 only on a private network or inside a container.
  const host = process.env.HOST || '127.0.0.1';
  server.listen(port, host, () => {
    // Never the key: only whether one is set, and the model name.
    console.log(`Report AI gateway on ${host}:${port}; DeepSeek ${key ? `configured (model ${model})` : 'NOT configured (503)'}; ${origins.length} allowed origin(s).`);
  });
}
