import { randomUUID } from 'node:crypto';
import { setTimeout as sleep } from 'node:timers/promises';
import { pathToFileURL } from 'node:url';
import { exactOrigin, isInstallToken, isPlaceholder, pageGatewayConfig } from '../services/report_ai/config.mjs';

const pagesOrigin = 'https://meftah7.github.io';
const startupStatuses = new Set([502, 503, 504]);

export async function checkReportAiGateway({
  origin, token, browserOrigin = pagesOrigin, smoke = false, fetchImpl = fetch,
  waitForRetry = () => sleep(5_000),
}) {
  async function request(path, options = {}) {
    const attempts = options.method === 'POST' ? 1 : 3;
    for (let attempt = 1; ; attempt++) {
      let response;
      try {
        response = await fetchImpl(origin + path, {
          ...options, redirect: 'error', signal: AbortSignal.timeout(45_000),
        });
      } catch {
        if (attempt === attempts) {
          throw new Error(path + ': could not reach the gateway. Check hosting status, DNS, TLS and proxy routing.');
        }
      }
      if (response && (attempt === attempts || !startupStatuses.has(response.status))) {
        return response;
      }
      await response?.body?.cancel().catch(() => {});
      await waitForRetry();
    }
  }
  const preflight = await request('/v1/documents/summarize', {
    method: 'OPTIONS',
    headers: {
      Origin: browserOrigin,
      'Access-Control-Request-Method': 'POST',
      'Access-Control-Request-Headers': 'authorization,content-type,idempotency-key',
    },
  });
  if (startupStatuses.has(preflight.status)) {
    throw new Error('Gateway did not become available for OPTIONS (HTTP ' + preflight.status + '). Check host startup logs.');
  }
  const allowed = name => (preflight.headers.get(name) ?? '').toLowerCase().split(',').map(v => v.trim());
  if (preflight.status !== 204 ||
      preflight.headers.get('access-control-allow-origin') !== browserOrigin ||
      !allowed('access-control-allow-methods').includes('post') ||
      !['authorization', 'content-type', 'idempotency-key'].every(
        name => allowed('access-control-allow-headers').includes(name),
      )) {
    throw new Error('Gateway CORS preflight failed. Check REPORT_AI_ORIGINS and proxy handling of OPTIONS.');
  }

  async function json(path, body) {
    const response = await request(path, {
      method: body ? 'POST' : 'GET',
      headers: {
        Origin: browserOrigin, Authorization: 'Bearer ' + token,
        ...(body ? { 'Content-Type': 'application/json', 'Idempotency-Key': randomUUID() } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    if (response.status === 401) {
      throw new Error(path + ': gateway rejected REPORT_AI_CLIENT_TOKEN (HTTP 401).');
    }
    if (!response.ok) throw new Error(path + ': gateway returned HTTP ' + response.status + '.');
    if (response.headers.get('access-control-allow-origin') !== browserOrigin) {
      throw new Error(path + ': gateway omitted the exact browser CORS origin.');
    }
    try { return await response.json(); } catch {
      throw new Error(path + ': response was not valid JSON.');
    }
  }

  const health = await json('/v1/health');
  if (health?.ready !== true || health.chat !== true ||
      health.summarize !== true || health.provider !== 'deepseek') {
    throw new Error('Gateway is reachable but chat and document summaries are not both ready.');
  }
  if (!smoke) return;

  const chat = await json('/v1/chat', {
    message: 'How do I change the language in the app?',
  });
  if (typeof chat?.reply !== 'string' || !chat.reply.trim() ||
      chat.medical !== false || chat.emergency !== false) {
    throw new Error('Synthetic app-support chat returned no usable reply.');
  }
  const summary = await json('/v1/documents/summarize', {
    text: 'Synthetic training handout. The library opens on Monday. Visitors should return borrowed books at the reception desk.',
    fileName: 'synthetic-training-handout.txt',
    lang: 'en',
    extractionComplete: true,
  });
  const summaryText = [summary?.overview, ...(Array.isArray(summary?.points) ? summary.points : [])]
    .filter(value => typeof value === 'string').join(' ');
  if (summary?.readable !== true || summary.partial !== false ||
      !/library|borrowed books/i.test(summaryText)) {
    throw new Error('Synthetic document summary returned no usable, grounded reply.');
  }
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  try {
    const args = process.argv.slice(2);
    if (args.some(value => !['--local', '--smoke'].includes(value))) {
      throw new Error('Usage: node tools/check_report_ai_deployment.mjs [--local] [--smoke]');
    }
    const local = args.includes('--local');
    const smoke = args.includes('--smoke');
    const config = local ? {
      mode: 'live',
      origin: exactOrigin(process.env.REPORT_AI_ORIGIN ?? ''),
      token: process.env.REPORT_AI_CLIENT_TOKEN,
      browserOrigin: 'http://localhost:8080',
    } : pageGatewayConfig(process.env);
    if (config.mode === 'offline') {
      if (smoke) throw new Error('A provider smoke test requires live mode.');
      console.log('Explicit offline deployment selected.');
    } else {
      if (!isInstallToken(config.token) || isPlaceholder(config.token)) {
        throw new Error('Set REPORT_AI_CLIENT_TOKEN to a generated base64url installation token.');
      }
      if (local && !['localhost', '127.0.0.1'].includes(new URL(config.origin).hostname)) {
        throw new Error('--local requires a loopback gateway origin.');
      }
      await checkReportAiGateway({ ...config, smoke });
      console.log(smoke
        ? 'Gateway readiness, CORS, synthetic chat and synthetic summary passed.'
        : 'Gateway readiness and Pages CORS preflight passed.');
    }
  } catch (error) {
    console.error('Care Navigator deployment: ' + error.message);
    process.exitCode = 1;
  }
}
