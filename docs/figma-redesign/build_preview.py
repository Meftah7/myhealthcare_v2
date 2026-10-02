"""Bundle the shared design and local fonts into an offline review page."""
from pathlib import Path
import base64

root = Path(__file__).resolve().parent
repo = root.parent.parent
fonts = [
    ('Inter', 400, 'Inter-Regular.ttf'),
    ('Inter', 500, 'Inter-Medium.ttf'),
    ('Inter', 600, 'Inter-SemiBold.ttf'),
    ('Inter', 700, 'Inter-Bold.ttf'),
    ('Lexend', 500, 'Lexend-Medium.ttf'),
    ('Lexend', 600, 'Lexend-Medium.ttf'),
]
css = []
for family, weight, name in fonts:
    data = base64.b64encode((repo / 'assets/fonts/static' / name).read_bytes()).decode()
    css.append("@font-face{font-family:'%s';font-style:normal;font-weight:%s;src:url(data:font/ttf;base64,%s) format('truetype');font-display:block;}" % (family, weight, data))
template = (root / 'preview-template.html').read_text()
preview = template.replace('/* BUNDLED_FONTS */', '\n'.join(css)).replace('/* DESIGN_SPEC */', (root / 'design.js').read_text())
(root / 'preview.html').write_text(preview)
print('Created offline preview.html with embedded fonts and design specification.')
