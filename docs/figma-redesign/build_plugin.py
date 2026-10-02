"""Bundle the offline native Figma plugin and its review inventory."""
from pathlib import Path
import json
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent
geometry = json.loads((root / 'geometry.json').read_text())
bundle = (root / 'design.js').read_text() + '\nconst D=MyHealthDesign;\nconst GEOMETRY=' + json.dumps(geometry, separators=(',', ':')) + ';\n' + (root / 'plugin-engine.js').read_text()
(root / 'code.js').write_text(bundle)
inventory = [{k:s[k] for k in ['id','name','role','width','height']} for s in geometry]
(root / 'screen-inventory.json').write_text(json.dumps(inventory, indent=2))
with ZipFile(root / 'myhealth-figma-builder.zip', 'w', ZIP_DEFLATED) as archive:
    for name in ['code.js','manifest.json','README.md','screen-inventory.json']:
        archive.write(root / name, name)
print('Bundled',len(inventory),'screens into code.js and myhealth-figma-builder.zip.')
