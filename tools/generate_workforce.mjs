import {readFileSync,writeFileSync} from 'node:fs';
import {demoRoster} from '../services/shared_api/workforce_manifest.mjs';
const output=new URL('../lib/data/seed/workforce_manifest.g.dart',import.meta.url);
const json=JSON.stringify(demoRoster());
if(json.includes("'''"))throw Error('Unsupported triple quote in roster configuration.');
const code="// GENERATED from assets/demo/workforce.json. Run node tools/generate_workforce.mjs.\nconst workforceManifestJson = r'''"+json+"''';\n";
if(process.argv.includes('--check')) {
  const current=readFileSync(output,'utf8').match(/r'''([\s\S]*?)'''/);
  if(!current || JSON.stringify(JSON.parse(current[1]))!==json)throw Error('Regenerate the Dart workforce manifest.');
} else writeFileSync(output,code);
