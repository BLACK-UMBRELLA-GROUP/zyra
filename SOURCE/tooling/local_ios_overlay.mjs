// Build-only offline projection of already cached public Swift packages.
// No SDK/source/dependency-cache edits, Git commands, downloads or stubs.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
const digest=b=>crypto.createHash('sha256').update(b).digest('hex');
const quote=s=>JSON.stringify(s);
const manifestName=name=>/^Package(?:@swift-\d+(?:\.\d+)*)?\.swift$/.test(name);
// SDK implementation headers named *_Private.h are public build inputs,
// not the Founder's exact prohibited credential directory.
const forbidden=name=>name==='.git'||name==='xcuserdata'||name==='PRIVATE — API KEYS — DO NOT SYNC';

function tree(root) {
  const files={};
  function walk(dir) {
    for(const entry of fs.readdirSync(dir,{withFileTypes:true})) {
      if(forbidden(entry.name))continue;
      const file=path.join(dir,entry.name);
      if(entry.isDirectory())walk(file);
      else if(entry.isFile())files[path.relative(root,file)]=digest(fs.readFileSync(file));
      else if(entry.isSymbolicLink()) {
        const link=fs.readlinkSync(file),target=path.resolve(path.dirname(file),link);
        if(path.isAbsolute(link)||!target.startsWith(root+path.sep)||target.split(path.sep).some(forbidden))throw Error('External cached source link: '+file);
        files[path.relative(root,file)]='link:'+link;
      }
    }
  }
  walk(root);return Object.fromEntries(Object.entries(files).sort(([a],[b])=>a.localeCompare(b)));
}

// Package manifests are Swift source. Match complete balanced calls while
// respecting strings/comments; never rewrite target source bodies.
function calls(text,name) {
  const found=[];const regex=new RegExp('\\.'+name+'\\s*\\(','g');let match;
  while((match=regex.exec(text))) {
    let depth=1,i=regex.lastIndex,string=false,escape=false,line=false,block=0;
    for(;i<text.length&&depth;i++) {
      const c=text[i],next=text[i+1];
      if(line){if(c==='\n')line=false;continue;}
      if(block){if(c==='/'&&next==='*'){block++;i++;}else if(c==='*'&&next==='/'){block--;i++;}continue;}
      if(string){if(escape)escape=false;else if(c==='\\')escape=true;else if(c==='"')string=false;continue;}
      if(c==='/'&&next==='/'){line=true;i++;continue;}
      if(c==='/'&&next==='*'){block=1;i++;continue;}
      if(c==='"'){string=true;continue;}
      if(c==='(')depth++;else if(c===')')depth--;
    }
    if(depth)throw Error('Unbalanced manifest call '+name);
    found.push({start:match.index,end:i,text:text.slice(match.index,i)});regex.lastIndex=i;
  }
  return found;
}
function replaceCalls(text,name,transform) {
  const list=calls(text,name);let result=text;
  for(const item of list.reverse()) {
    const replacement=transform(item.text);
    let end=item.end;
    if(replacement===''){while(/\s/.test(text[end]??'')&&end<text.length)end++;if(text[end]===',')end++;}
    result=result.slice(0,item.start)+replacement+result.slice(end);
  }
  return result;
}
function normalDeclarations(text) {
  return Object.fromEntries(['target','binaryTarget','product','library','executable'].map(name=>[name,calls(text,name).map(c=>c.text)]));
}
function validateManifest(text) {
  if(!/^import PackageDescription$/m.test(text)||/^import (?!PackageDescription\b)/m.test(text)||/\bProcess\s*\(|\.plugin\s*\(|\.package\s*\([^)]*\burl\s*:/s.test(text))throw Error('Non-local/executable manifest rejected');
}

export function prepareLocalIosOverlay(source,packet,label) {
  const review=path.resolve(source,'../REPORTS/EVIDENCE');
  if(path.dirname(packet)!==review||!path.basename(packet).startsWith('OA305_NO_GIT_OPTION2_DELIVERY_'))throw Error('Use the exact scoped delivery packet');
  if(!/^LOCAL_IOS_PROJECTION(?:_\d+)?$/.test(label)||fs.existsSync(path.join(packet,label+'.json')))throw Error('Use a new immutable projection label');
  const root=fs.mkdtempSync(path.join(packet,'LOCAL_IOS.'));
  const resolvedFile=path.join(source,'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved');
  const resolved=fs.readFileSync(resolvedFile),pins=JSON.parse(resolved).pins;
  if(pins.length!==8||pins.some(p=>p.kind!=='remoteSourceControl'||!p.state.revision))throw Error('Pinned dependency graph changed');
  const packages=path.join(root,'packages');fs.mkdirSync(packages);
  const urls=new Map(),records=[];
  for(const pin of pins) {
    const name=pin.location.split('/').at(-1).replace(/\.git$/,'');
    if(!/^[A-Za-z0-9_-]+$/.test(name))throw Error('Unexpected package name');
    urls.set(pin.location.toLowerCase().replace(/\.git$/,''),path.join(packages,name));
  }
  function projectManifest(original,label) {
    const removedTests=calls(original,'testTarget').map(c=>c.text);
    const withoutTests=replaceCalls(original,'testTarget',()=> '');
    let projected=withoutTests;const removedDependencies=[];
    projected=replaceCalls(projected,'package',call=> {
      const remote=call.match(/url:\s*"([^"]+)"/);
      if(!remote)return call;
      const url=remote[1],key=url.toLowerCase().replace(/\.git$/,'');
      if(key.endsWith('/ocmock')){removedDependencies.push(call);return '';}
      const local=urls.get(key);if(!local)throw Error('Uncached remote dependency: '+url);
      const alias=call.match(/name:\s*"([^"]+)"/);
      return '.package('+(alias?'name: '+quote(alias[1])+', ':'')+'path: '+quote(local)+')';
    });
    if(JSON.stringify(normalDeclarations(withoutTests))!==JSON.stringify(normalDeclarations(projected)))throw Error('Normal target/product drift in '+label);
    validateManifest(projected);
    return {projected,removedTests,removedDependencies};
  }
  for(const pin of pins) {
    const destination=urls.get(pin.location.toLowerCase().replace(/\.git$/,''));
    const cache=path.join(source,'build/ios/SourcePackages/checkouts',path.basename(destination));
    const before=tree(cache);
    fs.cpSync(cache,destination,{recursive:true,verbatimSymlinks:true,filter:file=>!forbidden(path.basename(file))});
    const manifests={};
    for(const name of fs.readdirSync(destination).filter(manifestName)) {
      const manifest=path.join(destination,name);
      const original=fs.readFileSync(manifest,'utf8'),projection=projectManifest(original,pin.identity+'/'+name);
      fs.chmodSync(manifest,0o644);fs.writeFileSync(manifest,projection.projected);
      manifests[name]={before:digest(Buffer.from(original)),after:digest(Buffer.from(projection.projected)),removedTestTargets:projection.removedTests,removedUnusedDependencies:projection.removedDependencies};
    }
    const after=tree(destination);
    for(const file of Object.keys(before))if(!manifests[file]&&before[file]!==after[file])throw Error('Copied source drift: '+pin.identity+'/'+file);
    if(Object.keys(before).length!==Object.keys(after).length)throw Error('Copied package inventory drift');
    records.push({identity:pin.identity,declaredPin:pin.state,cache,destination,before,after,manifests});
  }
  const generated=path.join(source,'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage');
  const generatedCopy=path.join(packages,'FlutterGeneratedPluginSwiftPackage');
  fs.cpSync(generated,generatedCopy,{recursive:true,filter:file=>!forbidden(path.basename(file))});
  const plugin=path.join(source,'ios/Flutter/ephemeral/Packages/.packages/google_sign_in_ios-6.3.0');
  const pluginCopy=path.join(packages,'google_sign_in_ios');
  // The generated plugin path is a public pub-cache source symlink. Copy the
  // real package contents, not repository metadata or a fake dependency.
  fs.cpSync(fs.realpathSync(plugin),pluginCopy,{recursive:true,filter:file=>!forbidden(path.basename(file))});
  const pluginBefore=tree(fs.realpathSync(plugin)),pluginManifest=path.join(pluginCopy,'Package.swift');
  const originalPlugin=fs.readFileSync(pluginManifest,'utf8'),projectedPlugin=projectManifest(originalPlugin,'google_sign_in_ios');
  fs.chmodSync(pluginManifest,0o644);
  fs.writeFileSync(pluginManifest,projectedPlugin.projected);
  const pluginAfter=tree(pluginCopy);
  for(const file of Object.keys(pluginBefore))if(file!=='Package.swift'&&pluginBefore[file]!==pluginAfter[file])throw Error('Plugin source drift');
  const externalPackages=[];const externalSeen=new Set();
  function pinExternal(logical) {
    if(externalSeen.has(logical))return;externalSeen.add(logical);
    const real=fs.realpathSync(logical);
    externalPackages.push({logical,real,files:tree(real)});
    for(const name of fs.readdirSync(logical).filter(manifestName)) {
      const manifest=fs.readFileSync(path.join(logical,name),'utf8');validateManifest(manifest);
      for(const item of calls(manifest,'package')) {
        const local=item.text.match(/path:\s*"([^"]+)"/);
        if(!local)throw Error('Non-filesystem external package edge');
        pinExternal(path.resolve(logical,local[1]));
      }
    }
  }
  const rootManifest=path.join(generatedCopy,'Package.swift'),rootOriginal=fs.readFileSync(rootManifest,'utf8');
  const rootProjected=replaceCalls(rootOriginal,'package',call=> {
    const match=call.match(/name:\s*"([^"]+)"\s*,\s*path:\s*"([^"]+)"/);
    if(!match)throw Error('Unexpected generated dependency');
    const dependency=match[1]==='google_sign_in_ios'?pluginCopy:path.resolve(generated,match[2]);
    if(match[1]!=='google_sign_in_ios')pinExternal(dependency);
    validateManifest(fs.readFileSync(path.join(dependency,'Package.swift'),'utf8'));
    return '.package(name: '+quote(match[1])+', path: '+quote(dependency)+')';
  });
  if(JSON.stringify(normalDeclarations(rootOriginal))!==JSON.stringify(normalDeclarations(rootProjected)))throw Error('Generated product/target drift');
  validateManifest(rootProjected);fs.writeFileSync(rootManifest,rootProjected);
  const ios=path.join(root,'ios');
  fs.cpSync(path.join(source,'ios'),ios,{recursive:true,filter:file=> {
    const relative=path.relative(path.join(source,'ios'),file);
    return !forbidden(path.basename(file))&&!relative.startsWith('Flutter/ephemeral/Packages')&&!file.endsWith('Package.resolved');
  }});
  fs.cpSync(path.join(source,'tooling'),path.join(root,'tooling'),{recursive:true});
  const pbx=path.join(ios,'Runner.xcodeproj/project.pbxproj'),originalPbx=fs.readFileSync(pbx,'utf8');
  const needle='relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;';
  if(originalPbx.split(needle).length!==2)throw Error('Expected one local root package reference');
  const projectedPbx=originalPbx.replace(needle,'relativePath = '+quote(generatedCopy)+';');
  fs.writeFileSync(pbx,projectedPbx);
  const receipt={schema:3,at:new Date().toISOString(),source,root,ios,sourceFilter:'exact credential directory only',resolvedSha256:digest(resolved),packages:records,externalPackages,plugin:{before:pluginBefore,after:pluginAfter,manifestOriginal:originalPlugin,manifestProjection:projectedPlugin.projected},generated:{original:rootOriginal,projection:rootProjected},nativeProject:{originalSha256:digest(Buffer.from(originalPbx)),projectedSha256:digest(Buffer.from(projectedPbx)),onlyChange:'absolute local generated-package address'},localOverlayFiles:tree(root)};
  fs.writeFileSync(path.join(packet,label+'.json'),JSON.stringify(receipt,null,2)+'\n',{flag:'wx'});
  return {ios,root,receipt};
}

export function verifyLocalIosOverlay(source,projectionFile) {
  const packet=path.dirname(projectionFile);
  if(!/^LOCAL_IOS_PROJECTION(?:_\d+)?\.json$/.test(path.basename(projectionFile)))throw Error('Unknown offline projection receipt');
  const receipt=JSON.parse(fs.readFileSync(projectionFile,'utf8'));
  const review=path.resolve(source,'../REPORTS/EVIDENCE');
  if(path.dirname(packet)!==review||!path.basename(packet).startsWith('OA305_NO_GIT_OPTION2_DELIVERY_')||receipt.schema!==3||receipt.sourceFilter!=='exact credential directory only'||receipt.source!==source||path.dirname(receipt.root)!==packet||!path.basename(receipt.root).startsWith('LOCAL_IOS.'))throw Error('Wrong offline projection owner');
  for(const domain of ['ios','tooling','packages']) {
    const current=tree(path.join(receipt.root,domain));
    const expected=Object.fromEntries(Object.entries(receipt.localOverlayFiles).filter(([name])=>name.startsWith(domain+'/')).map(([name,value])=>[name.slice(domain.length+1),value]));
    const generated='Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved';
    if(domain==='ios'&&current[generated]&&!expected[generated]) {
      const pins=JSON.parse(fs.readFileSync(path.join(receipt.root,domain,generated),'utf8')).pins;
      if(!Array.isArray(pins)||pins.length)throw Error('Unexpected generated remote resolution');
      delete current[generated];
    }
    if(JSON.stringify(current)!==JSON.stringify(expected))throw Error('Frozen overlay inventory/content drift: '+domain);
  }
  for(const item of receipt.externalPackages) {
    if(fs.realpathSync(item.logical)!==item.real||JSON.stringify(tree(item.real))!==JSON.stringify(item.files))throw Error('External plugin input drift: '+item.logical);
    for(const name of fs.readdirSync(item.logical).filter(manifestName))validateManifest(fs.readFileSync(path.join(item.logical,name),'utf8'));
  }
  const resolved=fs.readFileSync(path.join(source,'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved'));
  if(digest(resolved)!==receipt.resolvedSha256||digest(fs.readFileSync(path.join(source,'ios/Runner.xcodeproj/project.pbxproj')))!==receipt.nativeProject.originalSha256)throw Error('Native input authority drift');
  for(const name of ['zyra_xcode_backend.sh','zyra_xcode_backend.dart','no_git.sb','sdk_pins.json']) {
    if(digest(fs.readFileSync(path.join(source,'tooling',name)))!==digest(fs.readFileSync(path.join(receipt.root,'tooling',name))))throw Error('Native phase guard drift');
  }
  return receipt;
}
