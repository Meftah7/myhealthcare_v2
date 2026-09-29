"""Sort a Dart file's import block the way `directives_ordering` expects:
dart: imports, then package: imports, then relative imports, each group
alphabetical and separated by a blank line.

Files whose imports span several lines (conditional or multi-line `show`)
are left alone and reported.

Usage: python tools/sort_imports.py files...
"""
import io
import sys


def sort_file(path):
    s = io.open(path, encoding='utf-8').read()
    lines = s.split('\n')
    idx = [i for i, l in enumerate(lines) if l.startswith('import ')]
    if not idx:
        return False
    first, last = idx[0], idx[-1]
    block = lines[first:last + 1]
    if any(l.strip() and not l.startswith('import ') for l in block):
        print(f'skipped (non-import lines inside the import block): {path}')
        return False
    if any(not l.rstrip().endswith(';') for l in block if l.strip()):
        print(f'skipped (multi-line import): {path}')
        return False
    imports = sorted({l for l in block if l.strip()})
    groups = [
        [l for l in imports if l.startswith("import 'dart:")],
        [l for l in imports if l.startswith("import 'package:")],
        [l for l in imports
         if not l.startswith("import 'dart:") and
         not l.startswith("import 'package:")],
    ]
    new_block = []
    for g in groups:
        if g:
            if new_block:
                new_block.append('')
            new_block.extend(g)
    if new_block == block:
        return False
    lines[first:last + 1] = new_block
    io.open(path, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))
    return True


if __name__ == '__main__':
    changed = sum(sort_file(p) for p in sys.argv[1:])
    print(f'sorted {changed} file(s)')
