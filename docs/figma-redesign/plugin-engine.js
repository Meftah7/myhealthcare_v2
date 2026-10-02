// Native, offline Figma development plugin. The bundle provides D and GEOMETRY.
// Creates a dedicated review page; never replaces or deletes existing user work.
const PAGE_NAME = 'MyHealth Care — Complete Review';
const PREFIX = 'MyHealth Review';
const ledger = {page: null, nodes: [], variables: [], styles: [], screens: {}, warnings: []};
const links = [];
const colorVars = {};
const numberVars = {};
const componentMasters = {};
const typography = {};
let page, foundations;

function record(node) { ledger.nodes.push(node.id); return node; }
function cssColor(value) {
  if (!value || value === 'transparent') return null;
  const hex = /^#([0-9a-f]{6})$/i.exec(value);
  if (hex) return {r:parseInt(hex[1].slice(0,2),16)/255,g:parseInt(hex[1].slice(2,4),16)/255,b:parseInt(hex[1].slice(4,6),16)/255,a:1};
  const rgb = /rgba?\(([^)]+)\)/.exec(value);
  if (!rgb) throw new Error('Unsupported color: '+value);
  const channels=rgb[1].split(',').map(Number);
  return {r:channels[0]/255,g:channels[1]/255,b:channels[2]/255,a:channels.length===4?channels[3]:1};
}
function tokenFor(value) {
  const c=cssColor(value); if(!c || c.a===0) return null;
  return Object.keys(D.colors).find(k=>{const t=cssColor(D.colors[k]);return t&&Math.abs(t.r-c.r)<.001&&Math.abs(t.g-c.g)<.001&&Math.abs(t.b-c.b)<.001&&c.a===1;});
}
function paint(value) {
  const c=cssColor(value);if(!c||c.a===0)return [];
  let p={type:'SOLID',color:{r:c.r,g:c.g,b:c.b},opacity:c.a};
  const key=tokenFor(value);if(key&&colorVars[key])p=figma.variables.setBoundVariableForPaint(p,'color',colorVars[key]);
  return [p];
}
function number(node, property, value, family) {
  node[property]=value;
  const v=numberVars[family+'/'+value];if(v)node.setBoundVariable(property,v);
}
async function prepareFonts() {
  const fonts=await figma.listAvailableFontsAsync();
  const names={400:'Regular',500:'Medium',600:'Semi Bold',700:'Bold'};
  for(const family of ['Inter','Lexend'])for(const weight of [400,500,600,700]){
    const desired=family==='Lexend'?'Medium':names[weight];
    const available=fonts.find(f=>f.fontName.family===family&&f.fontName.style.replace(/\s/g,'').toLowerCase()===desired.replace(/\s/g,'').toLowerCase());
    const fallback=fonts.find(f=>f.fontName.family==='Inter'&&f.fontName.style===names[weight])||fonts.find(f=>f.fontName.family==='Inter'&&f.fontName.style==='Regular');
    if(!available&&!fallback)throw new Error('Install Inter before running this builder.');
    typography[family+'/'+weight]=(available||fallback).fontName;
    if(!available)ledger.warnings.push(family+' '+weight+' uses '+fallback.fontName.family+' '+fallback.fontName.style);
    await figma.loadFontAsync(typography[family+'/'+weight]);
  }
}
async function makeFoundations() {
  const collections=await figma.variables.getLocalVariableCollectionsAsync();
  const variables=await figma.variables.getLocalVariablesAsync();
  const collection=name=>collections.find(c=>c.name===name)||figma.variables.createVariableCollection(name);
  const primitives=collection(PREFIX+'/Primitives');const semantics=collection(PREFIX+'/Semantic');
  const variable=(name,c,type)=>{
    const found=variables.find(v=>v.name===name&&v.variableCollectionId===c.id);
    const v=found||figma.variables.createVariable(name,c,type);ledger.variables.push(v.id);return v;
  };
  for(const [key,value] of Object.entries(D.colors)){
    if(!value)continue;
    const raw=variable('color/'+key,primitives,'COLOR');raw.scopes=[];raw.setValueForMode(primitives.defaultModeId,cssColor(value));
    raw.setVariableCodeSyntax('WEB','var(--myhealth-'+key.replace(/[A-Z]/g,m=>'-'+m.toLowerCase())+')');
    const v=variable('color/'+key,semantics,'COLOR');
    v.scopes=['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR'];
    v.setValueForMode(semantics.defaultModeId,{type:'VARIABLE_ALIAS',id:raw.id});
    v.setVariableCodeSyntax('WEB','var(--myhealth-'+key.replace(/[A-Z]/g,m=>'-'+m.toLowerCase())+')');colorVars[key]=v;
  }
  const values={spacing:new Set([0]),radius:new Set([0])};
  const walk=n=>{values.spacing.add(n.gap||0);n.padding.forEach(v=>values.spacing.add(v));n.radii.forEach(v=>values.radius.add(v));n.children.forEach(walk)};
  GEOMETRY.forEach(s=>walk(s.tree));
  for(const family of ['spacing','radius'])for(const value of [...values[family]].sort((a,b)=>a-b)){
    const raw=variable(family+'/'+value,primitives,'FLOAT');raw.scopes=[];raw.setValueForMode(primitives.defaultModeId,value);
    const syntax='var(--myhealth-'+family+'-'+String(value).replace('.','-')+')';raw.setVariableCodeSyntax('WEB',syntax);
    const v=variable(family+'/'+value,semantics,'FLOAT');v.scopes=[family==='radius'?'CORNER_RADIUS':'GAP'];
    v.setValueForMode(semantics.defaultModeId,{type:'VARIABLE_ALIAS',id:raw.id});v.setVariableCodeSyntax('WEB',syntax);numberVars[family+'/'+value]=v;
  }
}
function textStyle(g) {
  const family=g.font.startsWith('Lexend')?'Lexend':'Inter';
  const key=[family,g.size,g.weight,g.lineHeight,g.tracking].join('/');
  if(!typography[key]){
    const name=PREFIX+'/Type/'+key;
    const style=existingStyles.find(s=>s.name===name)||figma.createTextStyle();
    style.name=name;style.fontName=typography[family+'/'+g.weight]||typography[family+'/400'];style.fontSize=g.size;
    style.lineHeight={unit:'PIXELS',value:g.lineHeight||g.size*1.45};style.letterSpacing={unit:'PIXELS',value:g.tracking||0};
    ledger.styles.push(style.id);typography[key]=style;
  }
  return typography[key];
}
async function text(g) {
  const n=record(figma.createText());n.name=g.name.slice(0,150);await n.setTextStyleIdAsync(textStyle(g).id);
  n.characters=g.text||'';n.fills=paint(g.color);n.textAlignHorizontal=(g.textAlign==='center'?'CENTER':g.textAlign==='right'?'RIGHT':'LEFT');
  n.textAutoResize='NONE';n.resize(Math.max(1,g.width),Math.max(1,g.height));return n;
}
function decorate(n,g) {
  n.fills=paint(g.bg);n.strokes=g.strokeWidth?paint(g.stroke):[];n.strokeWeight=g.strokeWidth||0;n.strokeAlign='INSIDE';
  ['topLeftRadius','topRightRadius','bottomRightRadius','bottomLeftRadius'].forEach((key,i)=>number(n,key,g.radii[i]||0,'radius'));
}
function autoLayout(n,g) {
  n.layoutMode=g.direction==='row'?'HORIZONTAL':'VERTICAL';
  n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';
  n.primaryAxisAlignItems=g.justify==='center'?'CENTER':g.justify==='space-between'?'SPACE_BETWEEN':g.justify==='flex-end'?'MAX':'MIN';
  n.counterAxisAlignItems=g.align==='center'?'CENTER':g.align==='flex-end'?'MAX':'MIN';
  number(n,'itemSpacing',g.gap||0,'spacing');
  ['paddingTop','paddingRight','paddingBottom','paddingLeft'].forEach((key,i)=>number(n,key,g.padding[i]||0,'spacing'));
  n.strokesIncludedInLayout=true;
}
function variantKey(g) {
  return [g.kind,g.bg,g.color,g.stroke,g.strokeWidth,g.radii.join(','),g.size,g.weight,g.padding.join(',')].join('|');
}
function appearance(g) {
  if(g.kind==='chip')return tokenFor(g.bg)==='primary'?'Selected':'Default';
  if(g.kind==='badge')return {greenTint:'Success',amberTint:'Pending',redTint:'Attention',blueTint:'Information'}[tokenFor(g.bg)]||'Default';
  const c=cssColor(g.bg);
  return !c||c.a===0?'Ghost':c.a<1?'On primary':tokenFor(g.bg)==='primary'?'Primary':'Secondary';
}
async function master(g) {
  const key=variantKey(g);if(componentMasters[key])return componentMasters[key];
  let hash=2166136261;for(let i=0;i<key.length;i++)hash=Math.imul(hash^key.charCodeAt(i),16777619);
  const name=PREFIX+'/'+g.kind+'/'+(hash>>>0).toString(16);
  const set=foundations.findOne(n=>n.type==='COMPONENT_SET'&&n.name===PREFIX+'/'+g.kind);
  const existing=foundations.children.find(n=>n.type==='COMPONENT'&&n.name===name)||(set&&set.children.find(n=>n.name==='Appearance='+appearance(g)));
  if(existing){
    const label=existing.findAllWithCriteria({types:['TEXT']}).find(n=>n.name==='Label');
    const owner=existing.parent.type==='COMPONENT_SET'?existing.parent:existing;
    const property=label?.componentPropertyReferences?.characters||Object.keys(owner.componentPropertyDefinitions).find(p=>p.startsWith('Label#'));
    componentMasters[key]={node:existing,property,kind:g.kind,appearance:appearance(g)};return componentMasters[key];
  }
  const n=record(figma.createComponent());foundations.appendChild(n);
  n.name=name;n.description='Editable '+g.kind+' with a Label property. Colors, spacing and radii use MyHealth Review variables.';
  decorate(n,g);autoLayout(n,{...g,direction:'row',align:'center',justify:'center',gap:0});
  n.resize(Math.max(1,g.width),Math.max(1,g.height));
  const label=await text({...g,name:'Label',width:Math.max(1,g.width-g.padding[1]-g.padding[3]),height:g.lineHeight||18,text:'Label'});
  n.appendChild(label);label.textAutoResize='WIDTH_AND_HEIGHT';
  const property=n.addComponentProperty('Label','TEXT','Label');label.componentPropertyReferences={characters:property};
  n.x=(Object.keys(componentMasters).length%4)*270;n.y=Math.floor(Object.keys(componentMasters).length/4)*90+90;
  componentMasters[key]={node:n,property,kind:g.kind,appearance:appearance(g)};return componentMasters[key];
}
async function build(g,spec) {
  let n;
  if(g.kind==='text')n=await text(g);
  else if(g.kind==='icon'){
    n=record(figma.createNodeFromSvg('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="'+(D.colors[spec.style.color]||spec.style.color)+'" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"><path d="'+(D.icons[spec.icon]||D.icons.record)+'"/></svg>'));
    n.resize(Math.max(1,g.width),Math.max(1,g.height));n.name=spec.icon;
    const variable=colorVars[spec.style.color];if(variable)n.findAll(v=>v.type==='VECTOR').forEach(v=>{v.strokes=v.strokes.map(p=>p.type==='SOLID'?figma.variables.setBoundVariableForPaint(p,'color',variable):p)});
  }else if(['button','chip','badge'].includes(g.kind)){
    const m=await master(g);n=record(m.node.createInstance());n.setProperties({[m.property]:g.text});n.resize(Math.max(1,g.width),Math.max(1,g.height));n.name=g.name;
  }else{
    n=record(figma.createFrame());n.name=g.name;decorate(n,g);autoLayout(n,g);n.clipsContent=false;
    n.resize(Math.max(1,g.width),Math.max(1,g.height));
    for(const [i,child] of g.children.entries()){const childNode=await build(child,(spec.children||[])[i]);n.appendChild(childNode)}
  }
  if(g.target)links.push({node:n,target:g.target});return n;
}
function status(message,done=false){figma.ui.postMessage({type:'status',message,done,ledger:done?ledger:null})}
function captureExisting(g,n){
  if(g.target)links.push({node:n,target:g.target});
  if(!g.children.length)return;
  if(!('children' in n)||n.children.length!==g.children.length)throw new Error('Existing screen structure differs at '+n.name+'. Your edits were preserved.');
  g.children.forEach((c,i)=>captureExisting(c,n.children[i]));
}
let existingStyles=[];
async function run() {
  figma.showUI('<html><body style="font:14px Inter,Arial;padding:20px;color:#152c49"><h3>MyHealth Care</h3><p id="status">Preparing the complete review…</p><button id="save" hidden>Download build report</button><button id="close">Close</button><script>let ledger;onmessage=e=>{const m=e.data.pluginMessage;if(m.type!=="status")return;document.getElementById("status").textContent=m.message;if(m.done){ledger=m.ledger;document.getElementById("save").hidden=false}};document.getElementById("close").onclick=()=>parent.postMessage({pluginMessage:{type:"close"}},"*");document.getElementById("save").onclick=()=>{const a=document.createElement("a");a.href=URL.createObjectURL(new Blob([JSON.stringify(ledger,null,2)],{type:"application/json"}));a.download="myhealth-figma-build-report.json";a.click()};<\/script></body></html>',{width:410,height:230});
  figma.ui.onmessage=m=>{if(m.type==='close')figma.closePlugin()};
  await prepareFonts();existingStyles=await figma.getLocalTextStylesAsync();
  page=figma.root.children.find(p=>p.name===PAGE_NAME)||record(figma.createPage());page.name=PAGE_NAME;
  await figma.setCurrentPageAsync(page);ledger.page=page.id;
  await makeFoundations();
  foundations=page.children.find(n=>n.name===PREFIX+'/Shared components')||record(figma.createFrame());
  foundations.name=PREFIX+'/Shared components';foundations.fills=paint(D.colors.surface);foundations.resize(1130,900);foundations.x=0;foundations.y=-1150;
  // Discover every required master before composing missing screens. This also
  // registers existing masters for safe grouping after an MCP continuation.
  async function inspectMasters(g){if(['button','chip','badge'].includes(g.kind))await master(g);for(const c of g.children)await inspectMasters(c)}
  for(const s of GEOMETRY)await inspectMasters(s.tree);
  const title=page.children.find(n=>n.name==='Board title')||await text({name:'Board title',text:'MyHealth Care · Auth / Patient / Staff / Admin\n'+GEOMETRY.length+' screens · synthetic examples · editable design review',font:'Lexend',size:24,weight:600,lineHeight:36,tracking:0,color:D.colors.ink,width:1800,height:80,textAlign:'left'});
  page.appendChild(title);title.x=0;title.y=-170;
  let sectionX=0;
  const sections=[];
  for(const [index,role] of D.roles.entries()){
    const name='0'+(index+1)+' · '+role.charAt(0).toUpperCase()+role.slice(1);
    const section=page.children.find(n=>n.type==='SECTION'&&n.name===name)||record(figma.createSection());section.name=name;
    section.x=sectionX;section.y=0;sections.push(section);
    const screens=GEOMETRY.filter(s=>s.role===role);const mobile=screens.filter(s=>s.width===390);let y=90;
    const columns=Math.min(5,mobile.length);const width=columns*438+96;
    for(let first=0;first<mobile.length;first+=columns){
      const row=mobile.slice(first,first+columns);let rowHeight=0;
      for(const [col,s] of row.entries()){
        const finalName=s.id+' · '+s.name;let frame=section.children.find(n=>n.name===finalName);
        if(!frame){frame=await build(s.tree,D.screens.find(d=>d.id===s.id).tree);section.appendChild(frame);frame.name=finalName;frame.clipsContent=true;frame.overflowDirection=s.height>844?'VERTICAL':'NONE';}
        else captureExisting(s.tree,frame);
        frame.x=48+col*438;frame.y=y;ledger.screens[s.id]=frame.id;rowHeight=Math.max(rowHeight,s.height);
      }y+=rowHeight+80;status('Built '+Object.keys(ledger.screens).length+' / '+GEOMETRY.length+' screens');
    }
    for(const s of screens.filter(s=>s.width!==390)){
      const finalName=s.id+' · '+s.name;let frame=section.children.find(n=>n.name===finalName);
      if(!frame){frame=await build(s.tree,D.screens.find(d=>d.id===s.id).tree);section.appendChild(frame);frame.name=finalName;frame.clipsContent=true;}
      else captureExisting(s.tree,frame);
      frame.x=48;frame.y=y;ledger.screens[s.id]=frame.id;y+=s.height+80;
    }
    section.resizeWithoutConstraints(Math.max(width,1536),y+48);sectionX+=section.width+160;
  }
  // Frame destinations are resolved after all four workspaces exist.
  let linked=0;
  for(const link of links){const destinationId=ledger.screens[link.target];if(!destinationId)throw new Error('Missing prototype destination: '+link.target);await link.node.setReactionsAsync([{trigger:{type:'ON_CLICK'},actions:[{type:'NODE',destinationId,navigation:'NAVIGATE',transition:null,preserveScrollPosition:false}]}]);linked++;}
  ledger.prototypeLinks=linked;ledger.screenCount=Object.keys(ledger.screens).length;
  ledger.warnings=[...new Set(ledger.warnings)];
  if(ledger.screenCount!==GEOMETRY.length)throw new Error('Screen inventory incomplete.');
  for(const kind of ['button','chip','badge']){
    const masters=Object.values(componentMasters).filter(m=>m.kind===kind);
    if(masters.length<2)continue;
    if(masters.every(m=>m.node.parent.type==='COMPONENT_SET'&&m.node.parent===masters[0].node.parent))continue;
    masters.forEach(m=>m.node.name='Appearance='+m.appearance);
    const set=record(figma.combineAsVariants(masters.map(m=>m.node),foundations));set.name=PREFIX+'/'+kind;
    set.fills=[];set.strokes=[];set.x=0;set.y={button:90,chip:270,badge:420}[kind];
    masters.forEach((m,i)=>{m.node.x=(i%2)*420;m.node.y=Math.floor(i/2)*70});set.resizeWithoutConstraints(840,Math.ceil(masters.length/2)*70);
  }
  foundations.resize(1130,Math.max(620,Math.ceil(Object.keys(componentMasters).length/4)*90+130));
  let overview=page.children.find(n=>n.name==='Overview · Four workspaces');
  if(!overview){
    overview=record(figma.createFrame());page.appendChild(overview);overview.name='Overview · Four workspaces';overview.layoutMode='VERTICAL';overview.primaryAxisSizingMode='AUTO';overview.counterAxisSizingMode='AUTO';overview.itemSpacing=20;overview.paddingTop=24;overview.paddingBottom=24;overview.paddingLeft=24;overview.paddingRight=24;overview.fills=paint(D.colors.page);
    const heading=await text({name:'Overview title',text:'MyHealth Care · One design, four workspaces',font:'Lexend',size:24,weight:600,lineHeight:36,tracking:0,color:D.colors.ink,width:1708,height:40,textAlign:'left'});overview.appendChild(heading);
    const grid=record(figma.createFrame());overview.appendChild(grid);grid.name='Workspace previews';grid.layoutMode='HORIZONTAL';grid.primaryAxisSizingMode='AUTO';grid.counterAxisSizingMode='AUTO';grid.itemSpacing=28;grid.fills=[];
    for(const [i,id] of ['auth-login','p-home','s-home','a-home'].entries()){
      const column=record(figma.createFrame());grid.appendChild(column);column.name=['Auth','Patient','Staff','Admin'][i];column.layoutMode='VERTICAL';column.primaryAxisSizingMode='AUTO';column.counterAxisSizingMode='AUTO';column.itemSpacing=12;column.fills=[];
      const label=await text({name:'Workspace label',text:column.name,font:'Inter',size:16,weight:600,lineHeight:24,tracking:0,color:D.colors.ink,width:390,height:24,textAlign:'left'});column.appendChild(label);
      const source=await figma.getNodeByIdAsync(ledger.screens[id]);const preview=record(source.clone());column.appendChild(preview);preview.name=column.name+' · Preview';
    }
    overview.x=0;overview.y=-2600;
  }
  ledger.nodes=[...new Set([...ledger.nodes,...page.findAll().map(n=>n.id)])];
  page.selection=[];figma.viewport.scrollAndZoomIntoView([overview]);
  status('Created '+ledger.screenCount+' editable screens in this file. Use the four canvas sections to review. '+(ledger.warnings.length?'Font fallbacks are listed in the report.':''),true);
}
run().catch(error=>{ledger.error=String(error);status('Build stopped: '+String(error)+'. Existing work was preserved. Download the report before closing.',true)});
