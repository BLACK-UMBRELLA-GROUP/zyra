import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn,spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {verifyLocalIosOverlay} from './local_ios_overlay.mjs';

const tooling=path.dirname(fileURLToPath(import.meta.url));
const source=path.dirname(tooling);
const pins=JSON.parse(fs.readFileSync(path.join(tooling,'sdk_pins.json'),'utf8'));
const sdk=pins.sdkRoot;
const policy=path.join(tooling,'no_git.sb');
const [mode,...args]=process.argv.slice(2);
const digest=buffer=>crypto.createHash('sha256').update(buffer).digest('hex');
function verifyPins() {
  for(const [file,expected] of Object.entries(pins.sha256)) {
    if(digest(fs.readFileSync(path.join(sdk,file)))!==expected)throw Error('SDK pin mismatch: '+file);
  }
  const version=JSON.parse(fs.readFileSync(path.join(sdk,'bin/cache/flutter.version.json'),'utf8'));
  if(version.frameworkVersion!==pins.frameworkVersion||version.channel!==pins.channel)throw Error('Unsupported SDK version');
}
verifyPins();
const baseEnv={...process.env,FLUTTER_ROOT:sdk,ZYRA_NO_GIT_ACTIVE:'pinned-v1'};
delete baseEnv.ZYRA_FOUNDER_MANUAL_SDK;
const dart=path.join(sdk,'bin/cache/dart-sdk/bin/dart');
const snapshot=path.join(sdk,'bin/cache/flutter_tools.snapshot');
const packages='--packages='+path.join(sdk,'packages/flutter_tools/.dart_tool/package_config.json');
function protectedRun(executable,parameters,cwd=source) {
  const child=spawn('/usr/bin/sandbox-exec',['-f',policy,executable,...parameters],{cwd,env:baseEnv,stdio:'inherit'});
  return new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',(code,signal)=>resolve({code,signal}));});
}
if(mode==='check') {
  // Prove exec denial with a harmless non-Git executable, never by running Git.
  const probe=spawnSync('/usr/bin/sandbox-exec',['-p',fs.readFileSync(policy,'utf8')+'\n(deny process-exec (literal "/usr/bin/false"))','/usr/bin/false'],{encoding:'utf8'});
  if(probe.status!==71||!probe.stderr.includes('Operation not permitted'))throw Error('Exec-denial proof failed');
  const nested=spawnSync('/usr/bin/sandbox-exec',['-p',fs.readFileSync(policy,'utf8')+'\n(deny process-exec (literal "/usr/bin/false"))','/bin/sh','-c','/bin/sh -c "exec /usr/bin/false"'],{encoding:'utf8'});
  if(nested.status!==1||!nested.stderr.includes('/usr/bin/false: Operation not permitted'))throw Error('Inherited exec-denial proof failed');
  console.log(JSON.stringify({sdk:pins.frameworkVersion,pins:5,execDenial:'PASS',nestedExecDenial:'PASS',policySha256:digest(fs.readFileSync(policy))}));
} else if(mode==='dart') {
  if(!['format','analyze','--version'].includes(args[0]))throw Error('Unsupported Dart operation');
  const result=await protectedRun(dart,args);verifyPins();process.exitCode=result.code??1;
} else if(mode==='flutter') {
  if(!['analyze','test','assemble'].includes(args[0]))throw Error('Use ios-profile for native build; no upgrade/run/package fetch here');
  const result=await protectedRun(dart,[packages,snapshot,'--no-version-check','--suppress-analytics',...args]);verifyPins();process.exitCode=result.code??1;
} else if(mode==='ios-profile') {
  // The recorded native attempt stopped before compilation because macOS
  // rejected SwiftPM's nested sandbox. Do not replay or disable Apple's
  // manifest protection; this prepared native route is not cleared yet.
  throw Error('AI native build is HELD: nested manifest sandbox refused. Founder-operated run.sh is retained; AI must not invoke it.');
  /* Prepared recipe retained for a separately verified toolchain repair.
  if(args.length!==1)throw Error('Native build requires the exact checked offline projection receipt');
  const projection=path.resolve(args[0]);
  const overlay=verifyLocalIosOverlay(source,projection);
  const nativeFiles=['ios/Runner.xcodeproj/project.pbxproj','ios/Runner.xcodeproj/xcshareddata/xcschemes/production.xcscheme','ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme'];
  for(const file of nativeFiles) {
    const text=fs.readFileSync(path.join(source,file),'utf8');
    if(text.includes('$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh')||!text.includes('zyra_xcode_backend.sh'))throw Error('Unrepaired native entry: '+file);
  }
  const cache=path.join(overlay.root,'SourcePackages');
  const resolved=path.join(source,'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved');
  const before=fs.readFileSync(resolved);
  if(!/^version: 1\.0\.0\+5$/m.test(fs.readFileSync(path.join(source,'pubspec.yaml'),'utf8')))throw Error('Version authority changed; revalidate native identity');
  const defines=['ZYRA_INTERNAL_FOUNDER_ACCESS=true','ZYRA_INTERNAL_FOUNDER_UUID=dfcbd00d-bc22-4d6e-999b-3a9264cf3510'].map(s=>Buffer.from(s).toString('base64')).join(',');
  const result=await protectedRun('/usr/bin/xcrun',[
    'xcodebuild','-workspace','Runner.xcworkspace','-scheme','production',
    '-configuration','Profile-production','-sdk','iphoneos',
    '-destination','generic/platform=iOS','-clonedSourcePackagesDirPath',cache,
    '-derivedDataPath',path.join(overlay.root,'DerivedData'),
    '-disableAutomaticPackageResolution','-onlyUsePackageVersionsFromResolvedFile','-skipPackageUpdates',
    'BUILD_DIR='+path.join(source,'build/ios'),
    'CONFIGURATION_BUILD_DIR='+path.join(source,'build/ios/iphoneos'),
    'FLUTTER_BUILD_MODE=profile','FLUTTER_ROOT='+sdk,'FLUTTER_TARGET=lib/main.dart',
    'FLAVOR=production','FLUTTER_BUILD_NAME=1.0.0','FLUTTER_BUILD_NUMBER=5',
    'FLUTTER_APPLICATION_PATH='+source,
    'DART_DEFINES='+defines,'ZYRA_NO_GIT_ACTIVE=pinned-v1','build',
  ],overlay.ios);
  if(!before.equals(fs.readFileSync(resolved)))throw Error('Swift package resolution drift; do not deliver');
  verifyPins();
  verifyLocalIosOverlay(source,projection);
  process.exitCode=result.code??1;
  */
} else {
  throw Error('Choose check, dart, flutter or ios-profile; this tool never installs or launches an app');
}
