# MyHealth Care — combined design review

The local board now contains **141 frames**: Auth **14**, Patient **56**, Staff **34**, Admin **37**. It expands the approved 78-frame baseline with existing app workflows identified by the comparison audit: profile photo management, actual Preferences controls, authenticated password changes, family consent, billing, clinical tools, notifications and admin operations. Patient, staff and admin each retain their desktop overview.

## View the updated design

Open [preview.html](preview.html) in your browser. It includes bundled fonts and works offline. Filter by role or search for a screen; linked actions navigate between review frames. Forms, switches and data are synthetic design examples. The Flutter app keeps its real controls, permission checks and data.

The [implementation notes](IMPLEMENTATION.md) record which Flutter components were upgraded and what still needs runtime validation. The machine-readable [mapping](implementation-map.json) connects all 141 frames to app sources; a mapping does not mean every state has a tested screenshot baseline.

## Editable Figma design

The [existing combined Figma file](https://www.figma.com/design/MPBXbXygNp0QFdc8ske81m) contains **56 frames from the original baseline**: Auth 9, Patient 31 and Staff 16. The expanded 141-frame specification has **not been synced to that remote file**. The earlier remote write stopped at Figma's Starter-plan MCP quota.

The included offline builder creates the complete expanded board as native editable frames, auto-layout, text, vector icons, variables, styles, components and prototype links. For the revised specification, use a **fresh blank Figma file**: the builder preserves and skips completed frame IDs, so running it over the old board would not refresh those existing frames.

1. Open a blank file in Figma Desktop. Install Inter and Lexend from `assets/fonts/static` if unavailable locally.
2. Choose **Plugins → Development → New plugin → Run once**. Replace its generated JavaScript entry with this folder's `code.js`. Keep the generated manifest and its real plugin ID. Its `main` must point to the entry file, `editorType` include `figma`, and `documentAccess` be `dynamic-page`; the included manifest illustrates these settings.
3. Run the development plugin. It creates **MyHealth Care — Complete Review**, with all four role sections and shared foundations in one file. Download the build report and inspect the result.

The plugin uses no network access and preserves other file contents. Re-running skips completed frames and stops if their layer structure no longer matches. Lexend fallback to Inter is recorded in its report. The plugin has passed JavaScript syntax checks; the revised bundle has not been executed in Figma in this session.

## Verification and remaining checks

- Chromium rendered all **141 frames** with no zero-sized layers or child bounds outside their parents; see [layout-check.json](layout-check.json). All **821 navigation targets** resolve to design frames.
- Earlier Figma readbacks verified node IDs, dimensions and descendant counts for the original 56 frames; see `figma-state-built.json`. Remote screenshots and the expanded board remain unverified.
- Flutter 3.44.4 / Dart 3.12.2 was recovered in a temporary SDK. Analysis reports no errors or warnings, and the web release build succeeds. The English/Arabic small-phone route matrix passes at combined text scales of 130%, 260% and 390%; see the [readability audit](../SMALL_PHONE_READABILITY_AUDIT.md) for coverage and limits. Physical-device and complete visual-state checks remain pending.
- The [full-app audit](../CURRENT_UI_VS_REDESIGN_AUDIT.md) and [78-frame baseline comparison](FRAME_BY_FRAME_AUDIT.md) explain the requirements behind this upgrade. They are historical comparison records, not a fresh visual audit of all 141 frames.

## Regenerate

`design.js` is the shared specification; `preview-template.html` renders it and `plugin-engine.js` builds Figma nodes. Run in order:

```sh
python3 docs/figma-redesign/build_preview.py
python3 docs/figma-redesign/check_layout.py --screenshots
python3 docs/figma-redesign/build_plugin.py
```

The layout checker requires Chromium and uses an isolated browser profile. Inspect the design and app separately: review navigation does not execute account changes, clinical writes or payments.
