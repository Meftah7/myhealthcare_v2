"""Derives every myhealth brand asset from the approved master image.

Usage (from the repository root):
    python tool/branding/generate_brand_assets.py

The master `assets/branding/myhealth-logo-original.png` is never modified.
Derived files and their uses are listed in `assets/branding/README.md`.

Method
- The master is RGBA with a soft outer glow and a few stray marks outside the
  navy rounded square. Derived logos keep only the rounded square: pixels are
  kept where the master's alpha is high (the square body is alpha 252-253),
  with a short alpha ramp for anti-aliased edges, and only inside the square's
  measured bounds. The body is made fully opaque. Nothing inside the square
  (crescent, M, stethoscope) is recoloured.
- The "symbol" layer (crescent + M + stethoscope without the navy square) is
  separated by colour distance from the navy, with edge colours
  un-premultiplied against the navy so no dark halo remains. It is used where
  a platform supplies its own background shape (Android adaptive foreground,
  maskable web icons) and for the monochrome notification silhouette.
- Full-bleed square icons (iOS, which applies its own corner mask) fill the
  rounded corners with the sampled navy instead of drawing a second rounded
  border.
"""

from __future__ import annotations

import json
import os
import shutil
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BRAND = os.path.join(ROOT, 'assets', 'branding')
MASTER = os.path.join(BRAND, 'myhealth-logo-original.png')


def p(*parts: str) -> str:
    return os.path.join(ROOT, *parts)


def save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, optimize=True)
    print('wrote', os.path.relpath(path, ROOT), img.size)


def fit(img: Image.Image, size: int, scale: float = 1.0,
        background=(0, 0, 0, 0)) -> Image.Image:
    """[img] centred on a [size]² canvas, longest side = size*scale."""
    w, h = img.size
    k = size * scale / max(w, h)
    resized = img.resize((max(1, round(w * k)), max(1, round(h * k))),
                         Image.LANCZOS)
    canvas = Image.new('RGBA', (size, size), background)
    canvas.alpha_composite(
        resized, ((size - resized.width) // 2, (size - resized.height) // 2))
    return canvas


def main() -> None:
    if not os.path.exists(MASTER):
        sys.exit(f'Missing approved master image: {MASTER}')
    src = np.asarray(Image.open(MASTER).convert('RGBA')).astype(np.float64)
    alpha = src[..., 3]

    # Measured bounds of the navy rounded square (alpha >= 240).
    ys, xs = np.where(alpha >= 240)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    square = src[y0:y1, x0:x1].copy()
    a = square[..., 3]
    # Edge ramp: glow (alpha <= 150) -> 0, body (>= 240) -> 255.
    ramp = np.clip((a - 150.0) / (240.0 - 150.0), 0.0, 1.0)
    square[..., 3] = ramp * 255.0
    logo = Image.fromarray(square.round().astype(np.uint8))

    # Navy: median of opaque, dark-blue body pixels.
    body = square[(ramp >= 1.0) & (square[..., 1] < 70)][:, :3]
    navy = np.median(body, axis=0)
    navy_hex = '#%02X%02X%02X' % tuple(int(round(v)) for v in navy)
    print('navy', navy_hex)

    # Symbol layer: the crescent (white) and M/stethoscope (teal) are bright
    # in green (>= 230) while the navy body and its bevelled edge stay <= ~61,
    # so green drives the alpha. Pixels near the square's edge are excluded
    # so the glow/bevel never leaves an outline. Colours are un-premultiplied
    # against the navy so no dark halo remains.
    from PIL import ImageFilter
    inner = Image.fromarray((ramp >= 1.0).astype(np.uint8) * 255)
    inner = np.asarray(inner.filter(ImageFilter.MinFilter(25))) / 255.0
    rgb = square[..., :3]
    sa = np.clip((rgb[..., 1] - 80.0) / (170.0 - 80.0), 0.0, 1.0) * inner
    # A faint highlight line along the square's top edge stays below 25%.
    sa = np.where(sa < 0.25, 0.0, sa)
    safe = np.where(sa > 0, sa, 1.0)[..., None]
    fg = np.clip((rgb - (1.0 - safe) * navy) / safe, 0, 255)
    sym = np.dstack([fg, sa * 255.0]).round().astype(np.uint8)
    symbol_full = Image.fromarray(sym)
    symbol = symbol_full.crop(symbol_full.getbbox())

    # Full-bleed square (iOS applies its own corner mask): solid navy with the
    # symbol at its original position, so no second rounded border shows.
    navy_rgba = tuple(int(round(v)) for v in navy) + (255,)
    full = Image.new('RGBA', logo.size, navy_rgba)
    full.alpha_composite(symbol_full)
    side = max(full.size)
    full = fit(full, side, background=navy_rgba)

    # --- Flutter assets -------------------------------------------------------
    pad = round(max(logo.size) * 0.03)
    padded = Image.new('RGBA', (logo.width + 2 * pad, logo.height + 2 * pad))
    padded.alpha_composite(logo, (pad, pad))
    save(fit(padded, 512), os.path.join(BRAND, 'myhealth-logo.png'))
    save(fit(logo, 256), os.path.join(BRAND, 'myhealth-logo-pdf.png'))
    save(fit(symbol, 1024, 0.92), os.path.join(BRAND, 'myhealth-symbol.png'))
    save(full.resize((1024, 1024), Image.LANCZOS).convert('RGB'),
         os.path.join(BRAND, 'myhealth-icon-fullbleed.png'))

    # --- Android -------------------------------------------------------------
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    res = p('android', 'app', 'src', 'main', 'res')
    for name, k in densities.items():
        save(fit(logo, round(48 * k), 0.92),
             os.path.join(res, f'mipmap-{name}', 'ic_launcher.png'))
        # Adaptive foreground; the XML insets it 16%, keeping the symbol in
        # the 66 dp safe zone so launcher masks never crop it.
        save(fit(symbol, round(108 * k), 0.92),
             os.path.join(res, f'drawable-{name}', 'ic_launcher_foreground.png'))
        save(fit(logo, round(96 * k)),
             os.path.join(res, f'drawable-{name}', 'splash_logo.png'))
        # Status-bar notification icon must be a white silhouette.
        mono = symbol.copy()
        mono.putdata([(255, 255, 255, px[3]) for px in mono.getdata()])
        save(fit(mono, round(24 * k), 0.9),
             os.path.join(res, f'drawable-{name}', 'ic_stat_myhealth.png'))
    colors = os.path.join(res, 'values', 'colors.xml')
    with open(colors, encoding='utf-8') as f:
        xml = f.read()
    import re
    xml = re.sub(r'(<color name="ic_launcher_background">)#[0-9A-Fa-f]{6}',
                 r'\g<1>' + navy_hex, xml)
    with open(colors, 'w', encoding='utf-8', newline='') as f:
        f.write(xml)

    # --- iOS -----------------------------------------------------------------
    appicon = p('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    with open(os.path.join(appicon, 'Contents.json'), encoding='utf-8') as f:
        contents = json.load(f)
    master_rgb = full.convert('RGB')
    for entry in contents['images']:
        if 'filename' not in entry:
            continue
        pt = float(entry['size'].split('x')[0])
        scale = float(entry['scale'].rstrip('x'))
        px = round(pt * scale)
        save(master_rgb.resize((px, px), Image.LANCZOS),
             os.path.join(appicon, entry['filename']))
    launch = p('ios', 'Runner', 'Assets.xcassets', 'LaunchImage.imageset')
    for suffix, k in (('', 1), ('@2x', 2), ('@3x', 3)):
        save(fit(logo, 120 * k), os.path.join(launch, f'LaunchImage{suffix}.png'))

    # --- Web -----------------------------------------------------------------
    save(fit(logo, 32, 0.96), p('web', 'favicon.png'))
    for s in (192, 512):
        save(fit(logo, s, 0.92), p('web', 'icons', f'Icon-{s}.png'))
        # Maskable: symbol inside the 80% safe circle on solid navy.
        save(fit(symbol, s, 0.66,
                 background=tuple(int(v) for v in navy) + (255,)),
             p('web', 'icons', f'Icon-maskable-{s}.png'))

    # --- Windows -------------------------------------------------------------
    ico = fit(logo, 256, 0.96)
    ico_path = p('windows', 'runner', 'resources', 'app_icon.ico')
    ico.save(ico_path, sizes=[(16, 16), (24, 24), (32, 32), (48, 48),
                               (64, 64), (128, 128), (256, 256)])
    print('wrote', os.path.relpath(ico_path, ROOT))

    with open(os.path.join(BRAND, 'navy.txt'), 'w', encoding='utf-8') as f:
        f.write(navy_hex + '\n')


if __name__ == '__main__':
    main()
