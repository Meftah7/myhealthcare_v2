// Report AI gateway for the full (local-Drift) MyHealth app.
//
// The local app keeps all clinical data on the device and has no server
// account, so it cannot call the shared API. This gateway is the only place
// the AI provider key lives: the app sends the text of ONE report the
// patient is already authorized to read (checked on the device by the app's
// access policy) plus a bounded question history, and receives a labelled
// draft explanation or a grounded answer whose quotes were verified against
// the report.
//
// Boundary: the gateway authenticates the client installation (a configured
// client token, compared by hash), not the patient. Patient/report
// authorization is enforced by the app before sending. For multi-user
// server data use the shared API's /api/reports/* endpoints, which check the
// signed-in patient and file ownership on the server.
//
// Nothing here logs report text, questions or credentials.

import { createServer } from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import {
  REPORT_INSTRUCTIONS, answerReportQuestion, clipReport, geminiReportChat, geminiReportExplainer,
} from '../shared_api/ai.mjs';

const MAX_BODY = 192 * 1024;
const PER_MINUTE = 30;

class GatewayError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

const sha256 = value => createHash('sha256').update(value).digest();

export function createGateway({ tokenHashes, origins = [], explainer, chat, now = () => Date.now() }) {
  const hashes = (tokenHashes ?? []).map(h => Buffer.from(h, 'hex'));
  const buckets = new Map();

  function authorize(req) {
    const raw = req.headers.authorization;
    if (typeof raw !== 'string' || !/^Bearer [A-Za-z0-9_-]{32,128}$/.test(raw)) {
      throw new GatewayError(401, 'Client not recognised.');
    }
    const presented = sha256(raw.slice(7));
    const ok = hashes.some(h => h.length === presented.length && timingSafeEqual(h, presented));
    if (!ok) throw new GatewayError(401, 'Client not recognised.');
    return presented.toString('hex').slice(0, 16);
  }
  function limit(client) {
    const time = now(), item = buckets.get(client);
    const next = !item || time - item.at >= 60000 ? { at: time, count: 1 } : { ...item, count: item.count + 1 };
    buckets.set(client, next);
    if (next.count > PER_MINUTE) throw new GatewayError(429, 'Too many requests. Try again later.');
  }
  async function readJson(req) {
    if (req.headers['content-type']?.split(';')[0] !== 'application/json') throw new GatewayError(415, 'Use JSON requests.');
    const chunks = []; let length = 0;
    for await (const chunk of req) {
      length += chunk.length;
      if (length > MAX_BODY) throw new GatewayError(413, 'Request too large.');
      chunks.push(chunk);
    }
    try { return JSON.parse(Buffer.concat(chunks).toString()); } catch { throw new GatewayError(400, 'Invalid JSON.'); }
  }
  function onlyFields(body, allowed) {
    if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).some(k => !allowed.includes(k))) {
      throw new GatewayError(400, 'Invalid request.');
    }
  }

  async function dispatch(req, path) {
    const client = authorize(req);
    if (path === '/v1/health' && req.method === 'GET') {
      return { explain: typeof explainer === 'function', chat: typeof chat === 'function' };
    }
    if (path === '/v1/reports/explain' && req.method === 'POST') {
      const body = await readJson(req);
      onlyFields(body, ['text']);
      if (typeof body.text !== 'string' || !body.text.trim() || body.text.length > 50000) {
        throw new GatewayError(400, 'Invalid report text.');
      }
      limit(client);
      if (typeof explainer !== 'function') throw new GatewayError(503, 'Report explanation is not configured.');
      const { document, coverage } = clipReport(body.text.trim());
      try {
        return { draft: true, answer: await explainer({ instructions: REPORT_INSTRUCTIONS, document }), coverage };
      } catch {
        throw new GatewayError(502, 'The explanation service failed. Try again later.');
      }
    }
    if (path === '/v1/reports/chat' && req.method === 'POST') {
      const body = await readJson(req);
      onlyFields(body, ['text', 'question', 'history']);
      limit(client);
      if (typeof chat !== 'function') throw new GatewayError(503, 'Report questions are not configured.');
      try {
        return await answerReportQuestion(chat, body);
      } catch (error) {
        if (/^Invalid /.test(error.message)) throw new GatewayError(400, error.message);
        throw new GatewayError(502, 'The answer service failed. Try again later.');
      }
    }
    throw new GatewayError(404, 'Endpoint unavailable.');
  }

  const server = createServer(async (req, res) => {
    const headers = {
      'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff', 'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy': "default-src 'none'; frame-ancestors 'none'",
    };
    try {
      const origin = req.headers.origin;
      if (origin && !origins.includes(origin)) throw new GatewayError(403, 'Origin not allowed.');
      if (origin) Object.assign(headers, { 'Access-Control-Allow-Origin': origin, Vary: 'Origin' });
      if (req.method === 'OPTIONS') {
        res.writeHead(204, { ...headers, 'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
          'Access-Control-Allow-Headers': 'Authorization,Content-Type' });
        res.end(); return;
      }
      const result = await dispatch(req, new URL(req.url, 'http://localhost').pathname);
      res.writeHead(200, { ...headers, 'Content-Type': 'application/json' });
      res.end(JSON.stringify(result));
    } catch (error) {
      const status = error instanceof GatewayError ? error.status : 500;
      res.writeHead(status, { ...headers, 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: error instanceof GatewayError ? error.message : 'Server could not complete the request.' }));
    }
  });
  server.requestTimeout = 60000; server.headersTimeout = 15000;
  return server;
}

/** Token hashes for REPORT_AI_CLIENT_TOKENS (comma-separated raw tokens). */
export function hashTokens(raw) {
  return (raw ?? '').split(',').map(t => t.trim()).filter(Boolean).map(t => sha256(t).toString('hex'));
}

// `node services/report_ai/server.mjs` — configuration from the environment
// (a secret store in production; never Git or a client build).
if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const key = process.env.MYHEALTH_AI_KEY;
  const model = process.env.MYHEALTH_AI_MODEL || undefined;
  const tokenHashes = hashTokens(process.env.REPORT_AI_CLIENT_TOKENS);
  if (tokenHashes.length === 0) throw new Error('Set REPORT_AI_CLIENT_TOKENS (32+ character client tokens).');
  const server = createGateway({
    tokenHashes,
    origins: (process.env.REPORT_AI_ORIGINS ?? '').split(',').filter(Boolean),
    explainer: key ? geminiReportExplainer({ apiKey: key, model }) : undefined,
    chat: key ? geminiReportChat({ apiKey: key, model }) : undefined,
  });
  const port = Number(process.env.PORT ?? 8790);
  server.listen(port, '127.0.0.1', () => {
    console.log(`Report AI gateway on loopback port ${port}; provider ${key ? 'configured' : 'NOT configured (503)'}.`);
  });
}
