# Drift on web (P0-11)

`sqlite3.wasm` and `drift_worker.js` in this folder are required for the local
database to work in a browser build. They are committed (not fetched at build
time) so the web build is reproducible and offline.

| File | Source | Version |
|---|---|---|
| `sqlite3.wasm` | https://github.com/simolus3/sqlite3.dart/releases | `sqlite3-3.5.2` (matches the resolved `sqlite3` package) |
| `drift_worker.js` | https://github.com/simolus3/drift/releases | `drift-2.34.3` (matches the resolved `drift` package) |

**When upgrading `drift` or `sqlite3`:** re-download both files from the release
tag matching the new package version, or the web DB will fail to open.

## Hosting headers (for OPFS)

Drift prefers OPFS storage, which needs the page to be **cross-origin isolated**.
Serve the build with:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Without these, drift automatically falls back to IndexedDB — still persistent,
slightly slower. The spike (P0-11) passed on both paths.

## Testing

`flutter test integration_test -d chrome` is **not supported** by Flutter. Web
integration tests run via `flutter drive` + a matching `chromedriver`:

```
chromedriver --port=4444 &
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/drift_spike_test.dart \
  -d web-server --browser-name=chrome --release
```
