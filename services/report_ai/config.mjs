export const CLIENT_TOKEN_PATTERN = /^[A-Za-z0-9_-]{32,128}$/;

export function exactOrigin(raw, { allowHttpLoopback = true } = {}) {
  let url;
  try {
    url = new URL(raw);
  } catch {
    throw new Error('Use a valid URL origin.');
  }
  const loopback = ['localhost', '127.0.0.1'].includes(url.hostname);
  if (url.protocol !== 'https:' &&
      !(allowHttpLoopback && loopback && url.protocol === 'http:')) {
    throw new Error('Use HTTPS. Loopback HTTP is allowed only for local testing.');
  }
  if (raw !== url.origin || raw.includes('*')) {
    throw new Error('Use only the exact origin, without a path, trailing slash, credentials or wildcard.');
  }
  return url.origin;
}

export function isInstallToken(token) {
  return typeof token === 'string' && CLIENT_TOKEN_PATTERN.test(token);
}

export function isPlaceholder(value) {
  return /(?:placeholder|replace[-_ ]?me|changeme|your[-_ ]?(?:client|gateway|deepseek)|example[-_ ]?(?:token|key))/i.test(value) ||
    /^(.)\1+$/.test(value);
}

export function pageGatewayConfig(env) {
  const mode = env.REPORT_AI_MODE || 'live';
  if (mode === 'offline') return { mode };
  if (mode !== 'live') throw new Error('REPORT_AI_MODE must be live or offline.');
  const raw = env.REPORT_AI_ORIGIN;
  if (!raw) throw new Error('Set the REPORT_AI_ORIGIN Actions variable to the deployed HTTPS gateway origin.');
  let origin;
  try {
    origin = exactOrigin(raw, { allowHttpLoopback: false });
  } catch (error) {
    throw new Error('REPORT_AI_ORIGIN: ' + error.message);
  }
  const hostname = new URL(origin).hostname;
  if (!hostname.includes('.') || /(?:^|\.)example\.(?:com|org|net)$|\.(?:example|invalid|test|localhost|local)$/.test(hostname) ||
      hostname === '127.0.0.1' || isPlaceholder(hostname)) {
    throw new Error('REPORT_AI_ORIGIN must point to a real public HTTPS gateway.');
  }
  const token = env.REPORT_AI_CLIENT_TOKEN;
  if (!isInstallToken(token) || isPlaceholder(token) || /^sk-/i.test(token)) {
    throw new Error('Set REPORT_AI_CLIENT_TOKEN to a generated base64url installation token (32–128 characters).');
  }
  return { mode, origin, token };
}

export function gatewayEnvironment(env) {
  const tokens = (env.REPORT_AI_CLIENT_TOKENS ?? '').split(',').map(t => t.trim()).filter(Boolean);
  if (!tokens.length || tokens.some(t => !isInstallToken(t) || isPlaceholder(t) || /^sk-/i.test(t))) {
    throw new Error('REPORT_AI_CLIENT_TOKENS must contain generated base64url installation tokens (32–128 characters).');
  }
  const origins = (env.REPORT_AI_ORIGINS ?? '').split(',').map(o => o.trim()).filter(Boolean);
  if (env.REPORT_AI_REQUIRE_PROVIDER === 'true' && !origins.length) {
    throw new Error('Set REPORT_AI_ORIGINS to the exact browser origin.');
  }
  for (const origin of origins) {
    try { exactOrigin(origin); } catch (error) {
      throw new Error('REPORT_AI_ORIGINS: ' + error.message);
    }
  }
  const key = env.DEEPSEEK_API_KEY?.trim();
  if ((env.REPORT_AI_REQUIRE_PROVIDER === 'true' && !key) ||
      (key && (key.includes('<') || isPlaceholder(key)))) {
    throw new Error('Set DEEPSEEK_API_KEY in the gateway runtime secret store.');
  }
  const portValue = env.PORT ?? '8790';
  const port = Number(portValue);
  if (!/^\d+$/.test(portValue) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer from 1 to 65535.');
  }
  return { tokens, origins, key, port, host: env.HOST || '127.0.0.1' };
}
