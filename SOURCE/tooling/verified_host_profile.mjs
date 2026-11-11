// Contained Dart-only PROFILE payload build using an exact measured native host.
// Uses the existing protected signing flow and the cached profile SDK.
// The native Xcode route is independent of this Dart-only build.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {assertReviewWorkspace, createReviewWorkspace, writeBuildEvidence} from './review_workspace.mjs';
import {checkVerifiedPhone, deliverVerifiedPhone} from './verified_phone_delivery.mjs';

const tooling = path.dirname(fileURLToPath(import.meta.url));
const source = path.dirname(tooling);
const reviews = path.resolve(source, '../REPORTS/EVIDENCE');
const sdk = '/opt/homebrew/share/flutter';
const host = path.join(source, 'build/ios/Profile-production-iphoneos/Runner.app');
const hostHash = '416b47b24d2f0d18892407450792ff88088f20ec7134f60fe970654fa68b16b6';
const hostFileCount = 177;
const nativeInputHash = '393cbfa300894ad517a9107aa254d7622647ff6ca65acd590a5dd28d1824e0a4';
const hostEntitlementsHash = '86dd1b7c3804b6b7a625757c78766f600e5a8fe854d74f2a139674239c9e9ec7';
const identity = 'Apple Development: Shakeel Ahmad (C5LDDW3Z2Z)';
const team = '9Y7Z8F36SJ';
const profileHash = '1af45878575c7449b427169878ace2caae4d39be5425fe54e1906fe6415b96d7';
const engine = 'bin/cache/artifacts/engine/ios-profile/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter';
const enginePayloadHash = 'eb7bfa2968b9005682fcf7506f5ddcbcea9d35c5551d7f55542f10d95022832a';
const sdkPins = {
  'bin/cache/dart-sdk/bin/dart': '3760a76d390be872c4b4a44a5d045f06183bc21b191b98c8f1e26bc9b1d65d20',
  'bin/cache/flutter_tools.snapshot': '13abc665bbccfaf78f1357ada1818adf27ed05663a1d3c4519da5b89e3ea0f1a',
  'bin/cache/flutter.version.json': '62b76a2190a0dc19abe64bc3f7feadcc8aaae6e8ba3e4199df519adcfcb9fbd0',
  'packages/flutter_tools/.dart_tool/package_config.json': '2e1fd90c83dcdedf42dc536969dd3297040cbb2114971f7774824dc1e3f59b93',
  'packages/flutter_tools/bin/xcode_backend.dart': '472073909ce8bde7f5844379c8949bc536a9889a7565a962608fd0da6bcda494',
  'packages/flutter_tools/lib/src/asset.dart': '3767f7741b0d258aad58b80440c2a43b2c6352364492718488a5082c4f28e942',
  'packages/flutter_tools/lib/src/build_system/targets/assets.dart': '6b882d4ef892fe53f658fa46735a18943cb4430d48c605f26dd5366ae836defc',
};
const policyText = '(version 1)\n(allow default)\n; Inherited by the entire Dart / Flutter / Xcode subprocess tree.\n; No fake Git, metadata forging, package-signature or signing bypass.\n(deny process-exec\n  (regex #"/[Gg][Ii][Tt]([^/]*)?$")\n  (literal "/opt/homebrew/share/flutter/bin/flutter")\n  (literal "/opt/homebrew/share/flutter/bin/dart"))\n';
const minFreeBytes = 2 * 1024 ** 3;
const checkedSourceCommit = '48fe8e4e93298752da28dbb57cd77b37934b9a8b';
const checkedEvidenceCommit = '61acf4a460e5e831de2be086fe50303b24051cd2';
const checkedSourceHash = '6ea39b1397e4f0a5247196fc39a3c17772cdbff232ca5298ac643ff92042a17c';
const localApplicationInputHash = '5825d1f59bf2aa8600c3e408210ef4bbf30bd6f78f1127d4bb283d29dee8423f';
const checkedRegression = Object.freeze({
  analyzeSha256: "2238242caab69cbd9d80ef8a8927d8094e87509293c67f21b410ff3088c1b2e9",
  testsSha256: "2e5396340e51ac28f2c8dc6269de63c22f739f77140f78eb1ebd4142755263e2",
  failureBaselineSha256: "5881612557e5ffc9d807871953ef32ba7022008a3c7e9bc851f97ff0cd600d0d",
  comparisonSha256: "28054ddb827f1b720d901721b68a91d58144843fc27179c9f694b490d2baac64",
  candidateFailureSetSha256: "5881612557e5ffc9d807871953ef32ba7022008a3c7e9bc851f97ff0cd600d0d",
  retainedSkipSetSha256: "515ba0de8caed46b2ec74ff3bbe63967beb4293636a9bbc6b72c5e7de69f544a",
  passes: 6996,
  failures: 38,
  skips: 122,
  suites: 534,
  newFailures: 0,
  resolvedBaselineFailures: 0,
  newSkips: 0,
  sameRetainedSkips: true,
});
const dartCache = '/Users/shakeelahmad/.pub-cache/hosted/pub.dev';

// Explicit public requirements, not a recursive scan of SOURCE or private data.
// These current-input pins are supplied by the main owner's checked plan. They
// prevent drift/new native requirements; they do not assert recompiling them.
export const requiredNativeInputs = [
  'pubspec.yaml', 'pubspec.lock', '.flutter-plugins-dependencies',
  '.dart_tool/package_config.json',
  'ios/Runner.xcodeproj/project.pbxproj',
  'ios/Runner.xcodeproj/xcshareddata/xcschemes/production.xcscheme',
  'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
  'ios/Runner.xcworkspace/contents.xcworkspacedata',
  'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved',
  'ios/Runner/Info.plist', 'ios/Runner/Runner.entitlements',
  'ios/Runner/AppDelegate.swift', 'ios/Runner/SceneDelegate.swift',
  'ios/Runner/Runner-Bridging-Header.h',
  'ios/Runner/GeneratedPluginRegistrant.h', 'ios/Runner/GeneratedPluginRegistrant.m',
  'ios/Flutter/AppFrameworkInfo.plist', 'ios/Flutter/Generated.xcconfig',
  'ios/Flutter/Profile.xcconfig', 'ios/Flutter/Profile-production.xcconfig',
  'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift',
];
const sha = buffer => crypto.createHash('sha256').update(buffer).digest('hex');
const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const sortedJson = object => JSON.stringify(Object.fromEntries(Object.entries(object).sort(([a], [b]) => a.localeCompare(b))));
const exactKeys = (value, allowed) => {
  if (!value || Array.isArray(value) || typeof value !== 'object' ||
      Object.keys(value).some(key => !allowed.includes(key))) throw Error('Unknown plan fields');
};
function plainFile(file) {
  if (!fs.lstatSync(file).isFile()) throw Error('Expected an explicit regular file: ' + file);
  const real = fs.realpathSync(file);
  if (real.split(path.sep).includes('PRIVATE — API KEYS — DO NOT SYNC')) throw Error('Protected path');
  return file;
}
function sourceFile(relative) {
  if (!validSourcePath(relative)) throw Error('Unapproved source input');
  const file = plainFile(path.join(source, relative));
  if (!fs.realpathSync(file).startsWith(fs.realpathSync(source) + path.sep)) throw Error('Source input escapes its owner');
  return file;
}
export function validSourcePath(relative) {
  if (typeof relative !== 'string' || path.isAbsolute(relative) || relative.includes('\\') ||
      relative.split('/').some(part => !part || part === '.' || part === '..' ||
        part === '.git' || part === 'PRIVATE — API KEYS — DO NOT SYNC')) return false;
  return /^(?:lib|test|assets|tooling)\//.test(relative) || requiredNativeInputs.includes(relative) ||
    relative === 'run.sh' || /^ios\/Runner\/Assets\.xcassets\//.test(relative);
}
function verifyFiles(files) {
  if (!files || Array.isArray(files) || typeof files !== 'object') throw Error('Missing input hashes');
  for (const [relative, hash] of Object.entries(files)) {
    if (!validSourcePath(relative) || !/^[a-f0-9]{64}$/.test(hash)) throw Error('Unapproved source input');
    const file = sourceFile(relative);
    if (sha(fs.readFileSync(file)) !== hash) throw Error('Checked input drift: ' + relative);
  }
}
function publicInventory(relativeRoot, include = () => true) {
  const entries = {};
  const actualSource = fs.realpathSync(source);
  function scan(relative) {
    const directory = path.join(source, relative);
    if (fs.lstatSync(directory).isSymbolicLink() || !fs.realpathSync(directory).startsWith(actualSource + path.sep)) throw Error('Public input directory escapes owner');
    for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
      if (entry.name === '.git' || entry.name === 'PRIVATE — API KEYS — DO NOT SYNC') continue;
      const child = path.join(relative, entry.name);
      if (entry.isDirectory()) scan(child);
      else if (entry.isFile()) {
        if (include(child)) entries[child] = sha(fs.readFileSync(sourceFile(child)));
      }
      else throw Error('Public source link refused: ' + child);
    }
  }
  scan(relativeRoot);
  return entries;
}
export function publicNativeInventory() {
  const entries = publicInventory('ios/Runner/Assets.xcassets');
  for (const relative of requiredNativeInputs) entries[relative] = sha(fs.readFileSync(sourceFile(relative)));
  return entries;
}
function exactPublicInventory(sealFiles) {
  const localFiles = {};
  for (const root of ['lib', 'test', 'assets', 'tooling']) {
    const expected = Object.fromEntries(Object.entries(sealFiles).filter(([relative]) => relative.startsWith(root + '/')));
    // The checkout retains ignored visual output in test/. It is not test code.
    const current = publicInventory(root, relative => Object.hasOwn(expected, relative) ||
      !/^test\/visual\/(?:candidates\/.+\.(?:png|json)|failures\/.+\.png)$/.test(relative));
    if (root === 'lib') {
      for (const relative of Object.keys(current)) {
        if (Object.hasOwn(expected, relative)) continue;
        localFiles[relative] = current[relative];
        delete current[relative];
      }
    }
    if (sortedJson(current) !== sortedJson(expected)) throw Error('Checked public input inventory/content drift: ' + root);
  }
  if (sha(Buffer.from(sortedJson(localFiles))) !== localApplicationInputHash) throw Error('Local application input drift');
  return localFiles;
}
function artifactEntries(root) {
  const entries = {};
  function scan(directory) {
    for (const item of fs.readdirSync(directory, {withFileTypes: true})) {
      if (item.name === '.git' || item.name === 'PRIVATE — API KEYS — DO NOT SYNC') throw Error('Unexpected artifact path');
      const file = path.join(directory, item.name);
      if (item.isDirectory()) scan(file);
      else if (item.isFile()) {
        const bytes = fs.readFileSync(file);
        entries[path.relative(root, file)] = {bytes: bytes.length, sha256: sha(bytes)};
      } else throw Error('Unexpected artifact link');
    }
  }
  scan(root);
  return Object.fromEntries(Object.entries(entries).sort(([a], [b]) => a.localeCompare(b)));
}

// Strict thin arm64 Mach-O: only signing geometry may change. A mutable copy is
// normalized in memory, never on disk. Everything else before the trailing
// signature (code, symbols, metadata, load commands) must remain byte-identical.
export function machoPayload(buffer) {
  if (buffer.length < 32 || buffer.readUInt32LE(0) !== 0xfeedfacf ||
      buffer.readUInt32LE(4) !== 0x0100000c) throw Error('Expected thin arm64 Mach-O');
  const commands = buffer.readUInt32LE(16), commandBytes = buffer.readUInt32LE(20);
  if (commands < 1 || commands > 512 || 32 + commandBytes > buffer.length) throw Error('Invalid Mach-O header');
  let offset = 32, signature, linkedit, uuid;
  for (let index = 0; index < commands; index++) {
    const cmd = buffer.readUInt32LE(offset), size = buffer.readUInt32LE(offset + 4);
    if (size < 8 || offset + size > 32 + commandBytes) throw Error('Invalid load command');
    if (cmd === 0x1d) {
      if (signature || size !== 16) throw Error('Invalid signature command');
      signature = {command: offset, offset: buffer.readUInt32LE(offset + 8), size: buffer.readUInt32LE(offset + 12)};
    }
    if (cmd === 0x19 && buffer.subarray(offset + 8, offset + 24).toString().replaceAll('\0', '') === '__LINKEDIT') {
      if (linkedit || size < 72) throw Error('Invalid linkedit command');
      linkedit = {command: offset, fileoff: Number(buffer.readBigUInt64LE(offset + 40)),
        filesize: Number(buffer.readBigUInt64LE(offset + 48)), vmsize: Number(buffer.readBigUInt64LE(offset + 32))};
    }
    if (cmd === 0x1b) uuid = buffer.subarray(offset + 8, offset + 24).toString('hex');
    offset += size;
  }
  if (offset !== 32 + commandBytes || !signature || !linkedit || !uuid ||
      signature.offset < offset || signature.offset + signature.size !== buffer.length ||
      linkedit.fileoff + linkedit.filesize !== buffer.length || linkedit.vmsize < linkedit.filesize ||
      signature.offset < linkedit.fileoff) throw Error('Uncontained Mach-O signature');
  const payload = Buffer.from(buffer.subarray(0, signature.offset));
  payload.fill(0, signature.command + 12, signature.command + 16);
  payload.fill(0, linkedit.command + 32, linkedit.command + 40);
  payload.fill(0, linkedit.command + 48, linkedit.command + 56);
  return {sha256: sha(payload), rawSha256: sha(buffer.subarray(0, signature.offset)),
    signatureOffset: signature.offset, signatureSize: signature.size, uuid, linkedit};
}
export function sameNativePayload(before, after) {
  const a = machoPayload(before), b = machoPayload(after);
  return a.sha256 === b.sha256 && a.signatureOffset === b.signatureOffset && a.uuid === b.uuid &&
    (b.linkedit.vmsize === a.linkedit.vmsize || b.linkedit.vmsize === Math.ceil(b.linkedit.filesize / 16384) * 16384);
}
// The measured objective_c native asset uses a one-architecture FAT wrapper.
// Keep the thin engine/Runner guards unchanged; accept only that exact wrapper
// shape here, with an identical header/padding and identical inner code/metadata.
// Only its contained signature size and corresponding FAT size may differ.
export function singleArm64FatAsset(buffer) {
  if (buffer.length < 28 || buffer.readUInt32BE(0) !== 0xcafebabe ||
      buffer.readUInt32BE(4) !== 1 || buffer.readUInt32BE(8) !== 0x0100000c) {
    throw Error('Expected single arm64 FAT native asset');
  }
  const subtype = buffer.readUInt32BE(12), offset = buffer.readUInt32BE(16),
    size = buffer.readUInt32BE(20), alignment = buffer.readUInt32BE(24);
  if (alignment > 30 || offset < 28 || offset % (2 ** alignment) !== 0 ||
      size < 32 || offset + size !== buffer.length) {
    throw Error('Uncontained FAT native asset');
  }
  const slice = buffer.subarray(offset);
  if (slice.readUInt32LE(4) !== 0x0100000c || slice.readUInt32LE(8) !== subtype) {
    throw Error('FAT architecture metadata mismatch');
  }
  machoPayload(slice); // Same signed thin-arm64 validation, including UUID.
  const prefix = Buffer.from(buffer.subarray(0, offset));
  prefix.fill(0, 20, 24);
  return {slice, prefix};
}
export function sameSingleArm64FatAssetPayload(before, after) {
  const a = singleArm64FatAsset(before), b = singleArm64FatAsset(after);
  return a.prefix.equals(b.prefix) && sameNativePayload(a.slice, b.slice);
}
// Genuine ios AOT App.framework output (including the measured old App) has
// a single-arm64 FAT wrapper. Validate that exact contained form, not a thin
// file and not a multi-architecture framework. This changes only validation
// of the new Dart payload; native Runner/engine guards stay thin and strict.
export function validateAotFrameworkPayload(buffer) {
  return machoPayload(singleArm64FatAsset(buffer).slice);
}
function unusedAssetRequirementSlice(buffer) {
  const {slice, prefix} = singleArm64FatAsset(buffer), metadata = machoPayload(slice);
  let offset = 32, uuidOffset;
  for (let index = 0; index < slice.readUInt32LE(16); index++) {
    const command = slice.readUInt32LE(offset), size = slice.readUInt32LE(offset + 4);
    if (command === 0x1b) {
      if (uuidOffset !== undefined || size !== 24 || offset + 24 > metadata.signatureOffset) {
        throw Error('Ambiguous unused native asset UUID command');
      }
      uuidOffset = offset + 8;
    }
    offset += size;
  }
  if (uuidOffset === undefined) throw Error('Missing unused native asset UUID command');
  const copy = Buffer.from(slice);
  copy.fill(0, uuidOffset, uuidOffset + 16);
  // Unlike actual-host re-signing, unused requirement comparison permits no
  // signing-geometry change: compare literal pre-signature bytes except UUID.
  return {slice: copy.subarray(0, metadata.signatureOffset), prefix};
}
// Requirement comparison ONLY for the freshly compiled asset that is discarded.
// The candidate retains the original asset, signature, UUID and resources
// byte-for-byte (assertHostDelta). No executable is patched or re-identified,
// and the Runner/engine/actual-host payload checks remain UUID-strict.
export function sameUnusedNativeAssetRequirements(before, after) {
  const a = unusedAssetRequirementSlice(before), b = unusedAssetRequirementSlice(after);
  return a.prefix.equals(b.prefix) && a.slice.equals(b.slice);
}
function verifySdkAndHost() {
  if (fs.readFileSync(path.join(tooling, 'no_git.sb'), 'utf8') !== policyText) throw Error('No-Git policy drift');
  for (const [relative, hash] of Object.entries(sdkPins)) {
    if (sha(fs.readFileSync(plainFile(path.join(sdk, relative)))) !== hash) throw Error('Pinned SDK drift: ' + relative);
  }
  const version = readJson(path.join(sdk, 'bin/cache/flutter.version.json'));
  if (version.frameworkVersion !== '3.44.2' || version.channel !== 'stable') throw Error('Unsupported SDK');
  for (let directory = host; directory !== source; directory = path.dirname(directory)) {
    if (!fs.lstatSync(directory).isDirectory() || fs.realpathSync(directory) !== directory) {
      throw Error('Pinned native host is not in the protected build directory');
    }
  }
  const entries = artifactEntries(host);
  if (Object.keys(entries).length !== hostFileCount || sha(Buffer.from(JSON.stringify(entries))) !== hostHash) {
    throw Error('Measured native host file list/content drift');
  }
  if (entries['embedded.mobileprovision']?.sha256 !== profileHash) throw Error('Profile drift');
  if (sha(Buffer.from(sortedJson(publicNativeInventory()))) !== nativeInputHash) throw Error('New native requirement');
  const engineBytes = fs.readFileSync(path.join(sdk, engine));
  const hostEngine = fs.readFileSync(path.join(host, 'Frameworks/Flutter.framework/Flutter'));
  const a = machoPayload(engineBytes), b = machoPayload(hostEngine);
  if (a.rawSha256 !== enginePayloadHash || b.rawSha256 !== enginePayloadHash ||
      a.signatureOffset !== b.signatureOffset || a.signatureSize !== b.signatureSize || !sameNativePayload(engineBytes, hostEngine)) {
    throw Error('Genuine profile engine is incompatible with host');
  }
  return {entries, runtimePins: {[engine]: sha(engineBytes),
    'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64': sha(fs.readFileSync(path.join(sdk, 'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64')))}};
}
function loadPlan(file) {
  const packet = path.dirname(file);
  if (path.dirname(packet) !== reviews || !/^ZYRA_LINE82_2026_11_11_[A-Z]$/.test(path.basename(packet)) ||
      path.basename(file) !== 'HOST_PROFILE_PLAN.json' || fs.realpathSync(packet) !== packet) {
    throw Error('Wrong owned delivery plan');
  }
  const plan = readJson(plainFile(file));
  exactKeys(plan, ['schema', 'source', 'sourceSeal', 'sourceCommit', 'evidenceCommit', 'nativeInputs', 'checks']);
  if (plan.schema !== 3 || plan.source !== source || plan.sourceSeal !== 'CHECKED_PREBUILD.json' ||
      plan.sourceCommit !== checkedSourceCommit || plan.evidenceCommit !== checkedEvidenceCommit) throw Error('Unchecked application source commit');
  const seal = readJson(plainFile(path.join(packet, plan.sourceSeal)));
  exactKeys(seal, ['source', 'sourceCommit', 'files']);
  if (seal.source !== source || seal.sourceCommit !== checkedSourceCommit || !seal.files?.['lib/main.dart']) {
    throw Error('Wrong source seal');
  }
  const appFiles = Object.fromEntries(Object.entries(seal.files).filter(([relative]) => /^(?:lib|test|assets)\//.test(relative)));
  if (sha(Buffer.from(sortedJson(appFiles))) !== checkedSourceHash) throw Error('Application input digest does not match the reviewed commit');
  verifyFiles(seal.files);
  const localFiles = exactPublicInventory(seal.files);
  if (sortedJson(plan.nativeInputs) !== sortedJson(publicNativeInventory()) ||
      sha(Buffer.from(sortedJson(plan.nativeInputs))) !== nativeInputHash) throw Error('Native requirements drift');
  const checks = plan.checks;
  exactKeys(checks, Object.keys(checkedRegression));
  if (sortedJson(checks) !== sortedJson(checkedRegression)) {
    throw Error('Missing exact line 82 regression check');
  }
  return {packet, plan, seal, localFiles, planHash: sha(fs.readFileSync(file)), sealHash: sha(fs.readFileSync(path.join(packet, plan.sourceSeal)))};
}
const freeBytes = () => {
  const stat = fs.statfsSync(source);
  return Number(stat.bavail) * Number(stat.bsize);
};
async function command(executable, args, input) {
  const allowed = ['/usr/bin/codesign', '/usr/bin/xcrun', '/usr/bin/security', '/usr/bin/plutil', '/usr/libexec/PlistBuddy', path.join(sdk, 'bin/cache/dart-sdk/bin/dart')];
  if (!allowed.includes(executable)) throw Error('Unknown executable');
  const environment = {...process.env, FLUTTER_ROOT: sdk, ZYRA_NO_GIT_ACTIVE: 'pinned-v1'};
  delete environment.ZYRA_FOUNDER_MANUAL_SDK;
  const chunks = [];
  const started = new Date().toISOString();
  const sandbox = executable === path.join(sdk, 'bin/cache/dart-sdk/bin/dart')
    ? ['-p', policyText + '\n(deny network-outbound)']
    : ['-f', path.join(tooling, 'no_git.sb')];
  const status = await new Promise((resolve, reject) => {
    const child = spawn('/usr/bin/sandbox-exec', [...sandbox, executable, ...args],
      {cwd: source, env: environment, stdio: [input === undefined ? 'ignore' : 'pipe', 'pipe', 'pipe']});
    for (const stream of ['stdout', 'stderr']) child[stream].on('data', bytes => {
      chunks.push({stream, text: bytes.toString()});
    });
    if (input !== undefined) {
      child.stdin.on('error', reject);
      child.stdin.end(input);
    }
    child.on('error', reject);
    child.on('close', (code, signal) => resolve({code, signal}));
  });
  const result = {started, finished: new Date().toISOString(), ...status,
    stdout: chunks.filter(c => c.stream === 'stdout').map(c => c.text).join(''),
    stderr: chunks.filter(c => c.stream === 'stderr').map(c => c.text).join('')};
  if (status.code !== 0 || status.signal) throw Error('Protected command failed: ' + executable + ' (' + status.code + ')');
  return result;
}
async function checkIdentity(app) {
  await command('/usr/bin/codesign', ['--verify', '--deep', '--strict', app]);
  const detail = await command('/usr/bin/codesign', ['-d', '--verbose=4', app]);
  const signatureFields = detail.stderr.split('\n');
  if (!signatureFields.includes('Authority=' + identity) || !signatureFields.includes('TeamIdentifier=' + team)) throw Error('Existing Development identity mismatch');
  const plist = await command('/usr/libexec/PlistBuddy', ['-c', 'Print :CFBundleIdentifier', '-c', 'Print :CFBundleDisplayName',
    '-c', 'Print :CFBundleShortVersionString', '-c', 'Print :CFBundleVersion', '-c', 'Print :MinimumOSVersion', path.join(app, 'Info.plist')]);
  if (plist.stdout.trim() !== 'app.zyraconnect.zyra\nZYRA\n1.0.0\n5\n15.0') throw Error('Main identity/version/OS mismatch');
  const entitlements = await command('/usr/bin/codesign', ['-d', '--entitlements', ':-', app]);
  if (sha(Buffer.from(entitlements.stdout)) !== hostEntitlementsHash) throw Error('Native entitlements drift');
  return entitlements.stdout;
}
async function checkProvision(app) {
  const provision = path.join(app, 'embedded.mobileprovision');
  if (sha(fs.readFileSync(plainFile(provision))) !== profileHash) throw Error('Embedded profile changed');
  const profile = (await command('/usr/bin/security', ['cms', '-D', '-i', provision])).stdout;
  const extract = async (key, format) => (await command('/usr/bin/plutil', ['-extract', key, format, '-o', '-', '-'], profile)).stdout.trim();
  const created = Date.parse(await extract('CreationDate', 'raw'));
  const expires = Date.parse(await extract('ExpirationDate', 'raw'));
  let devices;
  try {
    devices = JSON.parse(await extract('ProvisionedDevices', 'json'));
  } catch {
    throw Error('Cannot read pinned profile device membership');
  }
  if (!(created <= Date.now() && Date.now() < expires) || !Array.isArray(devices) || devices.length !== 1 ||
      devices.some(device => typeof device !== 'string' || !/^[a-f0-9-]+$/i.test(device))) {
    throw Error('Provisioning profile expired or has no checked devices');
  }
  return devices;
}
function verifyRuntimePins(pins) {
  for (const [relative, hash] of Object.entries(pins)) if (sha(fs.readFileSync(path.join(sdk, relative))) !== hash) throw Error('Runtime input drift');
}
function recheckPlan(file, original) {
  const current = loadPlan(file);
  if (current.planHash !== original.planHash || current.sealHash !== original.sealHash) throw Error('Original checked plan/source seal drift');
}
function compilerEntryPresent(file) {
  try {
    fs.lstatSync(file);
    return true; // Includes dangling symlinks: they are not absent markers.
  } catch (error) {
    if (error.code === 'ENOENT') return false;
    throw error;
  }
}
export function isWildcardRerunMarker(input, entryPresent = compilerEntryPresent) {
  if (typeof input !== 'string') return false;
  const name = path.basename(input);
  // Pinned Flutter asset.dart inserts this intentionally missing SOURCE-root
  // dependency when directory assets require unconditional incremental reruns.
  // It is not a readable input. Raw traversal, nested/relative lookalikes,
  // existing files/symlinks and all other missing inputs remain unapproved.
  return /^DOES_NOT_EXIST_RERUN_FOR_WILDCARD[0-9]{1,10}$/.test(name) &&
    input === path.join(source, name) && !entryPresent(input);
}
export function classifyCompilerDependency(input, markerRecords, entryPresent = compilerEntryPresent) {
  if (!isWildcardRerunMarker(input, entryPresent)) return false;
  if (markerRecords.length !== 0) throw Error('Multiple wildcard rerun markers refused');
  markerRecords.push({input, kind: 'intentional-missing-wildcard-dependency',
    producerSha256: sdkPins['packages/flutter_tools/lib/src/asset.dart']});
  return true;
}
export function verifyWildcardRerunRecords(records, entryPresent = compilerEntryPresent) {
  if (!Array.isArray(records) || records.length > 1 ||
      records.some(record => !record || record.kind !== 'intentional-missing-wildcard-dependency' ||
        record.producerSha256 !== sdkPins['packages/flutter_tools/lib/src/asset.dart'] ||
        !isWildcardRerunMarker(record.input, entryPresent))) {
    throw Error('Wildcard dependency marker changed or no longer absent');
  }
}
function verifyCompilationInputs(root, context, markerRecords) {
  const file = path.join(root, 'flutter-inputs.txt');
  const inputs = fs.readFileSync(plainFile(file), 'utf8').split('\n').filter(Boolean);
  if (!inputs.length) throw Error('Missing genuine compiler input list');
  const records = {};
  for (const input of inputs) {
    const absolute = path.resolve(input);
    if (absolute.split(path.sep).includes('PRIVATE — API KEYS — DO NOT SYNC')) throw Error('Protected compiler input');
    if (classifyCompilerDependency(input, markerRecords)) continue;
    const relative = path.relative(source, absolute);
    if (!relative.startsWith('..' + path.sep) && !path.isAbsolute(relative)) {
      const expected = context.seal.files[relative] ?? context.plan.nativeInputs[relative] ?? context.localFiles[relative];
      if (!expected && !/^\.dart_tool\/(?:flutter_build|hooks_runner|native_assets_builder)\//.test(relative)) {
        throw Error('Unsealed compiler input');
      }
      if (expected && sha(fs.readFileSync(plainFile(absolute))) !== expected) throw Error('Compiler input drift');
    } else if (!absolute.startsWith(sdk + path.sep) && !absolute.startsWith(dartCache + path.sep) &&
        !absolute.startsWith(root + path.sep)) {
      throw Error('Compiler input outside declared public roots');
    }
    if (fs.existsSync(absolute) && fs.lstatSync(absolute).isFile()) records[absolute] = sha(fs.readFileSync(plainFile(absolute)));
  }
  return records;
}
export function flutterAssembleArgs(products, root, sdkRoot) {
  const defines = ['ZYRA_INTERNAL_FOUNDER_ACCESS=true', 'ZYRA_INTERNAL_FOUNDER_UUID=dfcbd00d-bc22-4d6e-999b-3a9264cf3510'];
  // Genuine backend encoding: cached assemble decodes these before compilation.
  const encodedDefines = defines.map(value => Buffer.from(value).toString('base64')).join(',');
  return ['--packages=' + path.join(sdk, 'packages/flutter_tools/.dart_tool/package_config.json'),
    path.join(sdk, 'bin/cache/flutter_tools.snapshot'), '--no-version-check', '--suppress-analytics', 'assemble',
    '--output=' + products, '--build-inputs=' + path.join(root, 'flutter-inputs.txt'),
    '--build-outputs=' + path.join(root, 'flutter-outputs.txt'), '--resource-pool-size=1',
    '-dTargetPlatform=ios', '-dTargetFile=lib/main.dart', '-dBuildMode=profile', '-dFlavor=production',
    '-dIosArchs=arm64', '-dSdkRoot=' + sdkRoot, '-dTreeShakeIcons=false', '-dDartObfuscation=false',
    '-dCodesignIdentity=' + identity, '--DartDefines=' + encodedDefines, 'profile_ios_bundle_flutter_assets'];
}
function assertHostDelta(original, candidate) {
  if (!fs.lstatSync(candidate).isDirectory() || fs.realpathSync(candidate) !== candidate) {
    throw Error('Delivery candidate must be a direct build directory');
  }
  const entries = artifactEntries(candidate);
  for (const [relative, record] of Object.entries(original)) {
    if (relative.startsWith('Frameworks/App.framework/') || relative === '_CodeSignature/CodeResources') continue;
    if (relative === 'Runner') {
      if (!sameNativePayload(fs.readFileSync(path.join(host, relative)), fs.readFileSync(path.join(candidate, relative)))) throw Error('Native Runner payload changed');
    } else if (JSON.stringify(entries[relative]) !== JSON.stringify(record)) throw Error('Retained native host changed: ' + relative);
  }
  for (const relative of Object.keys(entries)) if (!Object.hasOwn(original, relative) && !relative.startsWith('Frameworks/App.framework/')) throw Error('New native artifact path: ' + relative);
  return {entries, sha256: sha(Buffer.from(JSON.stringify(entries)))};
}
async function deliver(file, context, measured, originalEntitlements, expectedBuildReceiptHash) {
  const root = assertReviewWorkspace(source, context.packet, 'HOST_PROFILE',
    path.join(source, 'build/review-work', path.basename(context.packet), 'HOST_PROFILE'));
  const candidate = path.join(root, 'Runner.app');
  const bytes = fs.readFileSync(plainFile(path.join(root, 'BUILD.json')));
  const receipt = JSON.parse(bytes);
  const published = readJson(plainFile(path.join(context.packet, 'BUILD.json')));
  if (sha(bytes) !== expectedBuildReceiptHash || receipt.schema !== 2 || receipt.success !== true || receipt.root !== root || receipt.candidate !== candidate ||
      receipt.commitSha !== context.plan.sourceCommit || published.commitSha !== receipt.commitSha ||
      receipt.planSha256 !== context.planHash || receipt.sourceSealSha256 !== context.sealHash ||
      receipt.reusedHostSha256 !== hostHash || published.success !== true ||
      published.buildReceipt !== path.join(root, 'BUILD.json') || published.buildReceiptSha256 !== sha(bytes)) throw Error('No exact successful build receipt');
  const recheckArtifact = async () => {
    recheckPlan(file, context);
    verifySdkAndHost();
    if (sortedJson(receipt.runtimePins) !== sortedJson(measured.runtimePins)) throw Error('Build runtime pins drift');
    verifyRuntimePins(receipt.runtimePins);
    verifyWildcardRerunRecords(receipt.compilerDependencyMarkers);
    const compilerInputs = verifyCompilationInputs(root, context, []);
    if (Object.keys(compilerInputs).length !== receipt.compilerInputs?.files ||
        sha(Buffer.from(sortedJson(compilerInputs))) !== receipt.compilerInputs.sha256) throw Error('Build compiler inputs drift');
    const checked = assertHostDelta(measured.entries, candidate);
    if (checked.sha256 !== receipt.artifact?.sha256) throw Error('Delivery artifact drift');
    if (await checkIdentity(candidate) !== originalEntitlements) throw Error('Delivery entitlements drift');
    await checkProvision(candidate);
    return true;
  };
  await recheckArtifact();
  const profileDevices = await checkProvision(candidate);
  const phone = await checkVerifiedPhone(profileDevices);
  if (!phone.ready) {
    console.log(JSON.stringify(phone));
    process.exitCode = 1;
    return;
  }
  const attempts = path.join(root, 'PHONE');
  if (!fs.existsSync(attempts)) fs.mkdirSync(attempts, {mode: 0o700});
  if (!fs.lstatSync(attempts).isDirectory() || fs.realpathSync(attempts) !== attempts) {
    throw Error('Phone attempt directory must stay inside the protected build workspace');
  }
  const priorAttempts = fs.readdirSync(attempts);
  for (const attempt of priorAttempts) {
    if (!/^attempt-[A-Za-z0-9]+$/.test(attempt)) throw Error('Unknown prior delivery state');
    const directory = path.join(attempts, attempt);
    if (fs.realpathSync(directory) !== directory) throw Error('Linked prior delivery state');
    const prior = readJson(plainFile(path.join(directory, 'DELIVERY.json')));
    if (prior.buildReceiptSha256 !== expectedBuildReceiptHash || prior.installAttempted !== false) {
      throw Error('An install was attempted for this candidate. Check its recorded state before any further action.');
    }
  }
  // mkdir with an exclusive sequence prevents two calls from starting the same attempt.
  const work = path.join(attempts, 'attempt-' + (priorAttempts.length + 1));
  fs.mkdirSync(work, {mode: 0o700});
  const delivery = await deliverVerifiedPhone({candidate, bundleIdentifier: 'app.zyraconnect.zyra', profileDevices, work, recheckArtifact});
  const {captureFile, ...safeDelivery} = delivery;
  const summary = {...safeDelivery, commitSha: receipt.commitSha, artifactSha256: receipt.artifact.sha256,
    planSha256: context.planHash, buildReceiptSha256: sha(bytes), sourceSealSha256: context.sealHash};
  fs.writeFileSync(path.join(work, 'DELIVERY.json'), JSON.stringify(summary, null, 2) + '\n', {flag: 'wx', mode: 0o600});
  console.log(JSON.stringify(summary));
  if (!summary.postVerified) process.exitCode = 1;
}
async function main() {
  const [mode, input, expectedBuildReceiptHash, ...unknown] = process.argv.slice(2);
  if (!['inspect', 'build', 'phone-check', 'deliver'].includes(mode) || !input || unknown.length ||
      (mode === 'deliver' ? !/^[a-f0-9]{64}$/.test(expectedBuildReceiptHash ?? '') : expectedBuildReceiptHash !== undefined)) {
    throw Error('Use inspect/build/phone-check with the exact HOST_PROFILE_PLAN.json, or deliver with the observed build receipt SHA-256');
  }
  const file = path.resolve(input), measured = verifySdkAndHost(), context = loadPlan(file);
  const originalEntitlements = await checkIdentity(host);
  const profileDevices = await checkProvision(host);
  if (mode === 'phone-check') {
    const phone = await checkVerifiedPhone(profileDevices);
    console.log(JSON.stringify(phone));
    return;
  }
  if (mode === 'deliver') {
    await deliver(file, context, measured, originalEntitlements, expectedBuildReceiptHash);
    return;
  }
  const space = freeBytes();
  if (mode === 'inspect') {
    console.log(JSON.stringify({sourceChecked: true, sourceCommit: context.plan.sourceCommit, hostFiles: hostFileCount, hostHash,
      genuineEngineCompatible: true, freeBytes: space, requiredFreeBytes: minFreeBytes,
      buildSpaceReady: space >= minFreeBytes, nativeXcodeRoute: 'HELD'}, null, 2));
    return;
  }
  if (space < minFreeBytes) throw Error('Native payload build held: less than 2 GiB free; no cache deletion performed');
  const commitSha = context.plan.sourceCommit;
  const flutterVersion = readJson(path.join(sdk, 'bin/cache/flutter.version.json')).frameworkVersion;
  const root = createReviewWorkspace(source, context.packet, 'HOST_PROFILE');
  const products = path.join(root, 'products'), candidate = path.join(root, 'Runner.app');
  fs.mkdirSync(products);
  const receipt = {schema: 2, started: new Date().toISOString(), commitSha, root, candidate,
    planSha256: context.planHash, sourceSealSha256: context.sealHash, reusedHostSha256: hostHash,
    fullXcodeBuild: false, installExecuted: false, success: false};
  try {
    const sdkResult = await command('/usr/bin/xcrun', ['--sdk', 'iphoneos', '--show-sdk-path']);
    const sdkRoot = sdkResult.stdout.trim();
    if (!/^\/Applications\/Xcode\.app\/Contents\/Developer\/Platforms\/iPhoneOS\.platform\/Developer\/SDKs\/iPhoneOS[^/]*\.sdk$/.test(sdkRoot)) throw Error('Unexpected iPhone SDK');
    const dart = path.join(sdk, 'bin/cache/dart-sdk/bin/dart');
    // Configuration is intentionally absent: an explicit Flavor already gives
    // the same production Dart flavor, without asking Xcode for package info.
    await command(dart, flutterAssembleArgs(products, root, sdkRoot));
    recheckPlan(file, context); verifySdkAndHost(); verifyRuntimePins(measured.runtimePins);
    receipt.compilerDependencyMarkers = [];
    const compilerInputs = verifyCompilationInputs(root, context, receipt.compilerDependencyMarkers);
    receipt.compilerInputs = {files: Object.keys(compilerInputs).length, sha256: sha(Buffer.from(sortedJson(compilerInputs)))};
    const appFramework = path.join(products, 'App.framework');
    const payload = fs.readFileSync(plainFile(path.join(appFramework, 'App')));
    validateAotFrameworkPayload(payload);
    if (!sameNativePayload(fs.readFileSync(path.join(host, 'Frameworks/Flutter.framework/Flutter')),
      fs.readFileSync(plainFile(path.join(products, 'Flutter.framework/Flutter'))))) throw Error('Generated profile engine differs from retained host');
    const manifest = 'Frameworks/App.framework/flutter_assets/NativeAssetsManifest.json';
    if (JSON.stringify(readJson(path.join(host, manifest))) !== JSON.stringify(readJson(path.join(appFramework, 'flutter_assets/NativeAssetsManifest.json')))) throw Error('New native assets required by Dart payload');
    const nativeAssets = path.join(products, 'native_assets');
    if (!fs.existsSync(nativeAssets) || fs.readdirSync(nativeAssets).some(name => name !== 'objective_c.framework' && name !== 'objective_c.framework.dSYM')) throw Error('Unknown native asset output');
    const freshNative = path.join(nativeAssets, 'objective_c.framework');
    const oldNative = path.join(host, 'Frameworks/objective_c.framework');
    const oldEntries = artifactEntries(oldNative), newEntries = artifactEntries(freshNative);
    for (const [relative, record] of Object.entries(oldEntries)) {
      if (relative === '_CodeSignature/CodeResources') continue;
      if (relative === 'objective_c') {
        if (!sameUnusedNativeAssetRequirements(fs.readFileSync(path.join(oldNative, relative)), fs.readFileSync(path.join(freshNative, relative)))) throw Error('Changed native asset requirements');
      } else if (JSON.stringify(newEntries[relative]) !== JSON.stringify(record)) throw Error('Changed native asset resource');
    }
    for (const relative of Object.keys(newEntries)) if (!Object.hasOwn(oldEntries, relative)) throw Error('New native asset resource');
    if (freeBytes() < minFreeBytes) throw Error('Low space after payload compile; packaging held');
    // Copy native host without its old Dart framework; original host untouched.
    const oldAppFramework = path.join(host, 'Frameworks/App.framework');
    verifyWildcardRerunRecords(receipt.compilerDependencyMarkers);
    fs.cpSync(host, candidate, {recursive: true, filter: from => from !== oldAppFramework && !from.startsWith(oldAppFramework + path.sep)});
    fs.cpSync(appFramework, path.join(candidate, 'Frameworks/App.framework'), {recursive: true});
    await command('/usr/bin/codesign', ['--verify', '--strict', path.join(candidate, 'Frameworks/App.framework')]);
    await command('/usr/bin/codesign', ['--force', '--sign', identity, '--timestamp=none',
      '--preserve-metadata=identifier,entitlements,requirements,flags,runtime', candidate]);
    if (await checkIdentity(candidate) !== originalEntitlements) throw Error('Native entitlements changed');
    await checkProvision(candidate);
    receipt.artifact = assertHostDelta(measured.entries, candidate);
    recheckPlan(file, context); verifySdkAndHost(); verifyRuntimePins(measured.runtimePins);
    verifyWildcardRerunRecords(receipt.compilerDependencyMarkers);
    if (sortedJson(verifyCompilationInputs(root, context, [])) !== sortedJson(compilerInputs)) {
      throw Error('Compiler dependencies changed during packaging');
    }
    receipt.runtimePins = measured.runtimePins;
    receipt.success = true;
  } catch (error) {
    receipt.failure = String(error);
  } finally {
    receipt.finished = new Date().toISOString();
    fs.writeFileSync(path.join(root, 'BUILD.json'), JSON.stringify(receipt, null, 2) + '\n', {flag: 'wx'});
    writeBuildEvidence(context.packet, receipt, {commitSha, flutterVersion, buildMode: 'profile',
      target: 'ios-arm64 / lib/main.dart / production'});
  }
  console.log(JSON.stringify({success: receipt.success, root, candidate: receipt.success ? candidate : null,
    failure: receipt.failure, fullXcodeBuild: false, installExecuted: false}, null, 2));
  if (!receipt.success) process.exitCode = 1;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(String(error)); process.exitCode = 1; });
}
