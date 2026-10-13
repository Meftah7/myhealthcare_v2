# myhealth branding assets

The product name is **myhealth** (lowercase). The approved mark is a deep navy
rounded square with a white crescent and a teal flowing "M" joined to a
stethoscope. It contains no text.

All derived files are produced by:

```
python tool/branding/generate_brand_assets.py
```

| File | Use |
| --- | --- |
| `myhealth-logo-original.png` | **Master reference.** The approved image exactly as supplied (1269×1240 RGBA, includes a soft outer glow). Never edit; not bundled into the app. |
| `myhealth-logo.png` | In-app logo (512², transparent outside the rounded square, 3% padding). Used only through `AppLogo` / `AppBrandLockup`. |
| `myhealth-logo-pdf.png` | PDF header logo (256², transparent outside the square). Embedded by `lib/services/pdf/brand_pdf.dart`. |
| `myhealth-symbol.png` | Crescent + M + stethoscope without the navy square (transparent). Source for Android adaptive foreground, maskable web icons and the monochrome notification icon. Not bundled. |
| `myhealth-icon-fullbleed.png` | 1024² opaque square: solid navy with the symbol in its original position. Source for iOS icons, which the system masks itself (no double rounded border). Not bundled. |
| `navy.txt` | Sampled navy (`#012D5E`), used for adaptive/maskable backgrounds. |

Platform outputs written by the script:

- Android: `mipmap-*/ic_launcher.png`, `drawable-*/ic_launcher_foreground.png` (adaptive, 16% inset keeps the symbol in the safe zone), `drawable-*/splash_logo.png` (native launch screen), `drawable-*/ic_stat_myhealth.png` (white silhouette for status-bar notifications), `values/colors.xml` `ic_launcher_background`.
- iOS: `AppIcon.appiconset/*` (opaque), `LaunchImage.imageset/*` (120 pt logo).
- Web: `favicon.png` (32²), `icons/Icon-192/512.png`, `icons/Icon-maskable-192/512.png` (symbol within the 80% safe circle on navy).
- Windows: `runner/resources/app_icon.ico` (16–256 px).

There is no SVG: a faithful vector version of the approved raster does not
exist, so the high-resolution PNG is the source.
