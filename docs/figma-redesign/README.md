# MyHealth Care — complete design review

One combined board contains 78 screens: Auth **9**, Patient **31**, Staff **16**, Admin **22**. Patient, staff and admin each include a desktop layout. The designs use the app's blue palette, Inter and Lexend, and synthetic records. Review flows cover registration, both recovery paths, booking, results, nutrition, family access, consultation, referral, ownership, billing and relevant pending/error/empty states.

## See the design immediately

Open `preview.html` in your browser. It is self-contained, including the fonts, and works offline. Use the four role filters or search. Linked actions jump to their destination screen; inputs and filter chips are visual examples rather than functioning application controls.

## Create the editable design in ONE Figma file

The [combined Figma file](https://www.figma.com/design/MPBXbXygNp0QFdc8ske81m) has been created. It already contains **56 editable screens**: Auth 9, Patient 31 and Staff 16, including the patient and staff desktop layouts. Figma's Starter-plan MCP quota stopped the next write, before the 22 Admin screens and prototype wiring. The complete 78-screen design remains available in `preview.html`.

The included builder completes the remaining Admin section and connects all review flows **inside that same file**, preserving the existing screens. It also adds an overview showing the four workspaces together.

1. Open the linked file in **Figma Desktop**. Install Inter and Lexend from this repository's `assets/fonts/static` folder if they are unavailable locally.
2. Open **Plugins → Development → New plugin**, choose **Run once**, and save its generated plugin folder. Replace that folder's generated JavaScript entry file with this folder's **`code.js`**. Keep Figma's generated **`manifest.json`**, including its real plugin `id`; ensure `main` points to your entry file, `editorType` includes `figma`, and `documentAccess` is `dynamic-page`. The included manifest shows these settings but intentionally omits a Figma-assigned ID.
3. In the linked file, run the development plugin you just created. It completes the existing page, **MyHealth Care — Complete Review**, with **Auth / Patient / Staff / Admin** canvas sections and shared editable components above them. Download the build report from the plugin window when it finishes.

The builder creates native auto-layout frames, editable text, SVG vector icons, variables, text styles, button/chip/badge variants and prototype navigation. It does not insert screenshots. It uses no network access and preserves existing file contents. Re-running skips completed screen frames; if the layer structure was edited, it stops rather than connecting the wrong layers. To rebuild a changed specification, use a fresh blank file. If Lexend is unavailable, the report records an Inter fallback.

The plugin setup follows the official [Figma development guide](https://developers.figma.com/docs/plugins/plugin-quickstart-guide/) and [manifest documentation](https://developers.figma.com/docs/plugins/manifest/).

## Validation and limits

- Chromium rendered all 78 screens; the geometry check found no zero-sized layers and no child bounds outside their parents. See `layout-check.json`.
- Figma returned IDs, dimensions and descendant counts for all 56 created screens. Inter and Lexend loaded without fallback. `figma-state-built.json` contains the returned node IDs and the 288 navigation actions awaiting wiring.
- Figma's quota also blocked the screenshot check. Remote visual verification, 22 Admin screens and all 409 prototype connections remain pending. The continuation plugin has passed JavaScript syntax checks, but cannot be executed from this session; inspect the four sections after running it.
- Prototype navigation shows review paths. It does not perform account changes, save clinical records, send messages or process payments.
- The design is now integrated into the Flutter application. See `IMPLEMENTATION.md` and `implementation-map.json` for all 78 screen mappings and validation. The earlier analysis remains in `../UI_UX_REDESIGN_PLAN.md`.

## Maintain the artifacts

`design.js` is the shared design specification. `preview-template.html` renders the review. `plugin-engine.js` creates Figma nodes. Regenerate in order:

```sh
python3 docs/figma-redesign/build_preview.py
python3 docs/figma-redesign/check_layout.py --screenshots
python3 docs/figma-redesign/build_plugin.py
```

The layout checker requires Chromium. It uses an isolated browser profile and captures output through a pipe because the Snap launcher cannot write its DOM dump directly to a redirected file.
