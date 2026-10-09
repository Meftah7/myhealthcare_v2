// Local acceptance server. Optional /api proxy keeps Flutter requests same-origin
// so the production Content-Security-Policy does not need to be weakened.
import { createServer, request } from 'node:http';
import { createReadStream, statSync } from 'node:fs';
import { extname, resolve, sep } from 'node:path';
import { pathToFileURL } from 'node:url';

export function createLocalServer(root, apiOrigin) {
  root = resolve(root);
  const api = apiOrigin ? new URL(apiOrigin) : null;
  if (api && (api.protocol !== 'http:' || !['localhost', '127.0.0.1'].includes(api.hostname) ||
    api.username || api.password || api.pathname !== '/' || api.search || api.hash)) {
    throw Error('The local API proxy requires a loopback HTTP origin.');
  }
  const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
    '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css',
    '.pdf': 'application/pdf', '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf' };
  return createServer((req, res) => {
    if (api && req.url.startsWith('/api/')) {
      const upstream = request(new URL(req.url, api), {
        method: req.method, headers: { ...req.headers, host: api.host },
      }, reply => {
        res.writeHead(reply.statusCode, reply.headers);
        reply.pipe(res);
      });
      upstream.on('error', () => {
        if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Local API unavailable.' }));
      });
      req.pipe(upstream);
      return;
    }
    if (!['GET', 'HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
    try {
      const path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
      const file = resolve(root, '.' + (path === '/' ? '/index.html' : path));
      if (!file.startsWith(root + sep) || !statSync(file).isFile()) throw Error('Not found');
      res.writeHead(200, { 'Content-Type': types[extname(file)] ?? 'application/octet-stream',
        'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
      if (req.method === 'HEAD') res.end();
      else createReadStream(file).on('error', () => res.destroy()).pipe(res);
    } catch { res.writeHead(404); res.end('Not found'); }
  });
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const [, , root, port = '8080', api] = process.argv;
  if (!root) throw Error('Usage: node tools/serve_local.mjs <root> [port] [loopback-api-origin]');
  createLocalServer(root, api).listen(Number(port), '127.0.0.1', () => console.log(`Local acceptance server on port ${port}`));
}
