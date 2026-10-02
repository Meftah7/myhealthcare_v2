"""Render the review and export geometry; Chromium output stays off the console."""
from pathlib import Path
from html.parser import HTMLParser
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parent

class GeometryParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag == 'script' and dict(attrs).get('id') == 'render-geometry':
            self.active = True

    def handle_endtag(self, tag):
        if tag == 'script':
            self.active = False

    def handle_data(self, data):
        if self.active:
            self.parts.append(data)

command = ['chromium', '--headless', '--no-sandbox', '--disable-gpu',
           '--disable-dev-shm-usage', '--user-data-dir=/tmp/myhealth-layout-export',
           '--allow-file-access-from-files', '--virtual-time-budget=6000',
           '--window-size=1900,1400', '--dump-dom', (ROOT / 'preview.html').as_uri()]
result = subprocess.run(command, capture_output=True, text=True, timeout=60)
if result.returncode:
    raise RuntimeError(result.stderr[-1000:])
parser = GeometryParser()
parser.feed(result.stdout)
if not parser.parts:
    raise RuntimeError('No geometry returned. Browser output: '+result.stderr[-500:])
screens = json.loads(''.join(parser.parts))
(ROOT / 'geometry.json').write_text(json.dumps(screens, separators=(',', ':')))
issues = []
counts = {'frames': 0, 'text': 0, 'icon': 0, 'button': 0, 'badge': 0, 'chip': 0}
def walk(node, parent=None, screen_id=None):
    counts['frames' if node['kind'] == 'frame' else node['kind']] += 1
    if node['width'] <= 0 or node['height'] <= 0:
        issues.append([screen_id, node['name'], 'zero dimensions'])
    if parent and (node['x'] < parent['x']-1 or node['y'] < parent['y']-1 or
                   node['x']+node['width'] > parent['x']+parent['width']+1 or
                   node['y']+node['height'] > parent['y']+parent['height']+1):
        issues.append([screen_id, node['name'], 'outside '+parent['name']])
    for child in node['children']:
        walk(child, node, screen_id)
for screen in screens:
    walk(screen['tree'], screen_id=screen['id'])
report = {'screens': len(screens), 'counts': counts, 'issues': issues}
(ROOT / 'layout-check.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report, indent=2))
if '--screenshots' in sys.argv:
    for role in ['auth', 'patient', 'staff', 'admin']:
        capture = command[:-2] + ['--screenshot=' + str(ROOT / ('preview-'+role+'.png')),
                                 (ROOT / 'preview.html').as_uri()+'?role='+role]
        result = subprocess.run(capture, capture_output=True, text=True, timeout=60)
        if result.returncode or not (ROOT / ('preview-'+role+'.png')).exists():
            raise RuntimeError('Screenshot failed for '+role+': '+result.stderr[-500:])
        print('Captured '+role+' review.')
