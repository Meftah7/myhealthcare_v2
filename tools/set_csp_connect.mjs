// Adds the report AI gateway's origin to the web build's Content-Security-
// Policy `connect-src`, so the browser lets the app call it — and nothing
// else is opened up.
//
//   node tools/set_csp_connect.mjs build/web/index.html https://ai.example.org
//
// The origin must be exact: https://host[:port] (http only for localhost /
// 127.0.0.1, for local testing). No wildcards, paths or query strings.

import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

export function exactOrigin(raw) {
  let url;
  try { url = new URL(raw); } catch { throw new Error(`"${raw}" is not a URL.`); }
  const local = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
  if (url.protocol !== 'https:' && !(url.protocol === 'http:' && local)) {
    throw new Error(`"${raw}" must use https (http only for localhost).`);
  }
  if (url.username || url.password || (url.pathname !== '/' && url.pathname !== '') || url.search || url.hash) {
    throw new Error(`"${raw}" must be an origin only (no path, query or credentials).`);
  }
  if (raw.includes('*')) throw new Error('Wildcards are not allowed.');
  return url.origin;
}

/** [html] with [origin] added to the CSP connect-src (once). */
export function withConnectOrigin(html, origin) {
  const exact = exactOrigin(origin);
  const meta = /(<meta http-equiv="Content-Security-Policy" content=")([^"]*)(")/;
  const match = html.match(meta);
  if (!match) throw new Error('No Content-Security-Policy meta tag found.');
  const directives = match[2].split(';').map(d => d.trim()).filter(Boolean);
  const i = directives.findIndex(d => d.startsWith('connect-src'));
  if (i < 0) throw new Error('The policy has no connect-src directive.');
  const sources = directives[i].split(/\s+/).slice(1);
  if (!sources.includes(exact)) sources.push(exact);
  directives[i] = ['connect-src', ...sources].join(' ');
  return html.replace(meta, `$1${directives.join('; ')}$3`);
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? '').href) {
  const [file, origin] = process.argv.slice(2);
  if (!file || !origin) {
    console.error('Usage: node tools/set_csp_connect.mjs <index.html> <gateway origin>');
    process.exit(2);
  }
  writeFileSync(file, withConnectOrigin(readFileSync(file, 'utf8'), origin));
  console.log(`connect-src now allows ${exactOrigin(origin)}`);
}
