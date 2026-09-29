"""Rewrite simple `Scaffold(appBar: AppBar(...), body: ...)` screens onto
`AppScaffold` (Phase 6).

Only unambiguous cases are rewritten: a Scaffold whose arguments are limited
to appBar / body / floatingActionButton / floatingActionButtonLocation, with
an AppBar limited to title / actions / bottom / leading /
automaticallyImplyLeading. Everything else is reported and left alone.
`centerBody: false` keeps each screen's existing layout.

Usage: python tools/migrate_app_scaffold.py [--apply] files...
"""
import io
import re
import sys

SCAFFOLD_KEYS = {'appBar', 'body', 'floatingActionButton',
                 'floatingActionButtonLocation'}
APPBAR_KEYS = {'title', 'actions', 'bottom', 'leading',
               'automaticallyImplyLeading'}


def match_paren(s, i):
    """Index of the ')' matching the '(' at s[i]."""
    depth = 0
    in_str = None
    j = i
    while j < len(s):
        c = s[j]
        if in_str:
            if c == '\\':
                j += 2
                continue
            if s.startswith(in_str, j):
                j += len(in_str)
                in_str = None
                continue
        else:
            if s.startswith("'''", j) or s.startswith('"""', j):
                in_str = s[j:j + 3]
                j += 3
                continue
            if c in '\'"':
                in_str = c
            elif c == '/' and s.startswith('//', j):
                j = s.index('\n', j)
                continue
            elif c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
                if depth == 0:
                    return j
        j += 1
    raise ValueError('unbalanced')


def split_args(body):
    """Top-level comma split of an argument list."""
    args, depth, start, in_str, j = [], 0, 0, None, 0
    while j < len(body):
        c = body[j]
        if in_str:
            if c == '\\':
                j += 2
                continue
            if body.startswith(in_str, j):
                j += len(in_str)
                in_str = None
                continue
        else:
            if body.startswith("'''", j) or body.startswith('"""', j):
                in_str = body[j:j + 3]
                j += 3
                continue
            if c in '\'"':
                in_str = c
            elif c == '/' and body.startswith('//', j):
                j = body.index('\n', j)
                continue
            elif c in '([{':
                depth += 1
            elif c in ')]}':
                depth -= 1
            elif c == ',' and depth == 0:
                args.append(body[start:j])
                start = j + 1
        j += 1
    if body[start:].strip():
        args.append(body[start:])
    return [a.strip() for a in args if a.strip()]


def named(arg):
    m = re.match(r'^(\w+)\s*:\s*(.*)$', arg, re.S)
    return (m.group(1), m.group(2).strip()) if m else (None, arg)


def convert(s):
    out, pos, changed, skipped = [], 0, 0, []
    for m in re.finditer(r'(const\s+)?\bScaffold\(', s):
        if m.start() < pos:
            continue
        open_i = m.end() - 1
        close_i = match_paren(s, open_i)
        args = split_args(s[open_i + 1:close_i])
        kv = dict(named(a) for a in args)
        line = s.count('\n', 0, m.start()) + 1
        if None in kv or not set(kv) <= SCAFFOLD_KEYS or 'appBar' not in kv \
                or 'body' not in kv:
            skipped.append((line, 'scaffold args ' + ','.join(
                k or '?' for k in kv)))
            continue
        appbar = kv['appBar']
        if not appbar.startswith('AppBar('):
            skipped.append((line, 'appBar not AppBar('))
            continue
        a_close = match_paren(appbar, len('AppBar'))
        a_kv = dict(named(a) for a in split_args(appbar[len('AppBar('):a_close]))
        if None in a_kv or not set(a_kv) <= APPBAR_KEYS:
            skipped.append((line, 'appBar args ' + ','.join(
                k or '?' for k in a_kv)))
            continue
        parts = []
        title = a_kv.pop('title', None)
        if title is not None:
            tm = re.match(r'^(?:const\s+)?Text\((.*)\)$', title, re.S)
            inner = split_args(tm.group(1)) if tm else None
            if inner and len(inner) == 1 and ':' not in inner[0].split('(')[0]:
                parts.append(f'title: {inner[0]}')
            else:
                parts.append(f'titleWidget: {title}')
        for k in ('leading', 'automaticallyImplyLeading', 'actions', 'bottom'):
            if k in a_kv:
                parts.append(f'{k}: {a_kv[k]}')
        for k in ('floatingActionButton', 'floatingActionButtonLocation'):
            if k in kv:
                parts.append(f'{k}: {kv[k]}')
        parts.append(f"body: {kv['body']}")
        parts.append('centerBody: false')
        out.append(s[pos:m.start()])
        out.append('AppScaffold(' + ', '.join(parts) + ',)')
        pos = close_i + 1
        changed += 1
    out.append(s[pos:])
    return ''.join(out), changed, skipped


def ensure_import(s, path):
    if 'core/presentation/app_scaffold.dart' in s:
        return s
    depth = path.replace('\\', '/').split('lib/')[1].count('/')
    rel = '../' * depth + 'core/presentation/app_scaffold.dart'
    lines = s.split('\n')
    idx = max(i for i, l in enumerate(lines) if l.startswith("import '"))
    lines.insert(idx + 1, f"import '{rel}';")
    return '\n'.join(lines)


def main():
    apply = '--apply' in sys.argv
    for path in [a for a in sys.argv[1:] if a != '--apply']:
        s = io.open(path, encoding='utf-8').read()
        new, changed, skipped = convert(s)
        print(f'{path}: {changed} converted; skipped {skipped}')
        if apply and changed:
            new = ensure_import(new, path)
            io.open(path, 'w', encoding='utf-8', newline='\n').write(new)


if __name__ == '__main__':
    main()
