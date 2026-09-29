"""Append new localization keys to app_en.arb and app_ar.arb.

Usage: python tools/add_arb_keys.py keys.json

keys.json maps each key to {"en": ..., "ar": ..., "placeholders": {...}?}.
Keys already present are skipped, so the script is safe to re-run. New
entries are appended as text before the closing brace, leaving the rest of
each file byte-for-byte unchanged.
"""
import io
import json
import sys


def main():
    with io.open(sys.argv[1], encoding='utf-8') as f:
        keys = json.load(f)
    for lang in ('en', 'ar'):
        path = f'lib/l10n/app_{lang}.arb'
        with io.open(path, encoding='utf-8') as f:
            text = f.read()
        existing = json.loads(text)
        lines = []
        for key, spec in keys.items():
            if key in existing:
                continue
            lines.append(f'  {json.dumps(key)}: {json.dumps(spec[lang], ensure_ascii=False)}')
            if lang == 'en' and 'placeholders' in spec:
                meta = json.dumps({'placeholders': spec['placeholders']})
                lines.append(f'  {json.dumps("@" + key)}: {meta}')
        if not lines:
            continue
        end = text.rstrip().rstrip('}').rstrip()
        text = end + ',\n' + ',\n'.join(lines) + '\n}\n'
        json.loads(text)  # still valid JSON
        with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(text)
    print('done')


if __name__ == '__main__':
    main()
