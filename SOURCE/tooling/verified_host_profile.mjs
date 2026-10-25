// Contained Dart-only PROFILE payload build using an exact measured native host.
// This is NOT a native source rebuild or a repair of the held Xcode route.
// No install/launch, Git, SDK wrapper, provisioning, trust or validation bypass.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const tooling = path.dirname(fileURLToPath(import.meta.url));
const source = path.dirname(tooling);
const reviews = path.resolve(source, '../REPORTS/EVIDENCE');
const sdk = '/opt/homebrew/share/flutter';
const oldPacket = path.join(reviews, 'OA151_CIRCLE_DISCUSSION_BUBBLE_2026_10_13.QnUZDh');
const oldReceipt = path.join(oldPacket, 'BUILT.json');
const host = path.join(reviews, 'OA305_NO_GIT_OPTION2_DELIVERY_2026_10_13.yqJ0ef/PRE/Runner.app');
const hostHash = '8f9041a5dd1d124cfa3aa0c2d334f4ce840c5c4baa1e00093dbf5a313773130a';
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
const checkNames = ['ANALYZE_FROZEN.json', 'BASE_REGRESSION_FROZEN.json', 'DISCUSSION_FROZEN.json'];
const minFreeBytes = 2 * 1024 ** 3;
const nodeRuntime = '/Users/shakeelahmad/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node';
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
function publicInventory(relativeRoot) {
  const entries = {};
  const actualSource = fs.realpathSync(source);
  function scan(relative) {
    const directory = path.join(source, relative);
    if (fs.lstatSync(directory).isSymbolicLink() || !fs.realpathSync(directory).startsWith(actualSource + path.sep)) throw Error('Public input directory escapes owner');
    for (const entry of fs.readdirSync(directory, {withFileTypes: true})) {
      if (entry.name === '.git' || entry.name === 'PRIVATE — API KEYS — DO NOT SYNC') continue;
      const child = path.join(relative, entry.name);
      if (entry.isDirectory()) scan(child);
      else if (entry.isFile()) entries[child] = sha(fs.readFileSync(sourceFile(child)));
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
  for (const root of ['lib', 'test', 'assets', 'tooling']) {
    const current = publicInventory(root);
    const expected = Object.fromEntries(Object.entries(sealFiles).filter(([relative]) => relative.startsWith(root + '/')));
    const sorted = object => JSON.stringify(Object.fromEntries(Object.entries(object).sort(([a], [b]) => a.localeCompare(b))));
    if (sorted(current) !== sorted(expected)) throw Error('Checked public input inventory/content drift: ' + root);
  }
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
  const built = readJson(plainFile(oldReceipt));
  const entries = artifactEntries(host);
  if (Object.keys(entries).length !== 177 || sha(Buffer.from(JSON.stringify(entries))) !== hostHash ||
      built.artifact.sha256 !== hostHash || JSON.stringify(entries) !== JSON.stringify(built.artifact.entries) ||
      !readJson(path.join(oldPacket, 'BUILD_PROFILE.json')).success ||
      !readJson(path.join(oldPacket, 'NATIVE_IDENTITY.json')).success) throw Error('Measured native-host lineage drift');
  if (sha(fs.readFileSync(path.join(host, 'embedded.mobileprovision'))) !== profileHash) throw Error('Profile drift');
  for (const relative of ['pubspec.yaml', 'pubspec.lock', 'ios/Runner.xcodeproj/project.pbxproj',
    'ios/Runner/Info.plist', 'ios/Runner/Runner.entitlements']) {
    if (sha(fs.readFileSync(plainFile(path.join(source, relative)))) !== built.files[relative]) throw Error('New native requirement: ' + relative);
  }
  const engineBytes = fs.readFileSync(path.join(sdk, engine));
  const hostEngine = fs.readFileSync(path.join(host, 'Frameworks/Flutter.framework/Flutter'));
  const a = machoPayload(engineBytes), b = machoPayload(hostEngine);
  if (a.rawSha256 !== enginePayloadHash || b.rawSha256 !== enginePayloadHash ||
      a.signatureOffset !== b.signatureOffset || a.signatureSize !== b.signatureSize || !sameNativePayload(engineBytes, hostEngine)) {
    throw Error('Genuine profile engine is incompatible with host');
  }
  return {entries, built, engine: a, runtimePins: {[engine]: sha(engineBytes),
    'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64': sha(fs.readFileSync(path.join(sdk, 'bin/cache/artifacts/engine/ios-profile/gen_snapshot_arm64')))}};
}
function loadPlan(file) {
  const packet = path.dirname(file);
  if (path.dirname(packet) !== reviews || !/^OA151_CIRCLE_DISCUSSION_ACTIONS_2026_10_13\.[A-Za-z0-9]+$/.test(path.basename(packet)) ||
      path.basename(file) !== 'HOST_PROFILE_PLAN.json') throw Error('Wrong owned delivery plan');
  const plan = readJson(plainFile(file));
  exactKeys(plan, ['schema', 'source', 'sourceSeal', 'nativeInputs', 'checks', 'checkHashes', 'scope']);
  if (plan.schema !== 1 || plan.source !== source || plan.sourceSeal !== 'CHECKED_PREBUILD.json' ||
      plan.scope !== 'current-dart-only-payload-retain-measured-native-host' ||
      JSON.stringify(plan.checks) !== JSON.stringify(checkNames)) throw Error('Unknown build scope/flags');
  const seal = readJson(plainFile(path.join(packet, plan.sourceSeal)));
  if (seal.source !== source || !seal.files?.['lib/main.dart']) throw Error('Wrong source seal');
  verifyFiles(seal.files);
  exactPublicInventory(seal.files);
  if (requiredNativeInputs.some(relative => !Object.hasOwn(plan.nativeInputs ?? {}, relative)) ||
      Object.keys(plan.nativeInputs ?? {}).some(relative => !requiredNativeInputs.includes(relative) &&
        !/^ios\/Runner\/Assets\.xcassets\//.test(relative))) throw Error('Incomplete/unknown native requirement pins');
  verifyFiles(plan.nativeInputs);
  const assets = publicInventory('ios/Runner/Assets.xcassets');
  const plannedAssets = Object.fromEntries(Object.entries(plan.nativeInputs).filter(([relative]) => relative.startsWith('ios/Runner/Assets.xcassets/')));
  const sorted = object => JSON.stringify(Object.fromEntries(Object.entries(object).sort(([a], [b]) => a.localeCompare(b))));
  if (sorted(assets) !== sorted(plannedAssets)) throw Error('Native public asset inventory/content drift');
  const expectedCheckFiles = plan.checks.flatMap(name => [name, name.replace(/\.json$/, '.log')]);
  if (!plan.checkHashes || Object.keys(plan.checkHashes).sort().join('\n') !== expectedCheckFiles.sort().join('\n')) throw Error('Missing exact check receipt/log bindings');
  for (const name of plan.checks) {
    const receiptFile = plainFile(path.join(packet, name)), logName = name.replace(/\.json$/, '.log');
    const logFile = plainFile(path.join(packet, logName));
    if (sha(fs.readFileSync(receiptFile)) !== plan.checkHashes[name] || sha(fs.readFileSync(logFile)) !== plan.checkHashes[logName]) throw Error('Positive check content drift');
    const receipt = readJson(receiptFile), log = fs.readFileSync(logFile, 'utf8');
    const analysis = name === 'ANALYZE_FROZEN.json';
    const started = Date.parse(receipt.started), finished = Date.parse(receipt.finished), frozen = Date.parse(seal.at);
    if (!receipt.success || receipt.status !== 0 || receipt.signal || receipt.error ||
        !Number.isFinite(frozen) || !Number.isFinite(started) || !Number.isFinite(finished) || frozen > started || started > finished ||
        !Array.isArray(receipt.args) || receipt.args[0] !== nodeRuntime || receipt.args[1] !== 'tooling/no_git_driver.mjs' ||
        receipt.args[2] !== 'flutter' || receipt.args[3] !== (analysis ? 'analyze' : 'test') ||
        (analysis ? !log.includes('No issues found!') :
          !log.includes('All tests passed!') || !Number.isInteger(receipt.passes) || receipt.passes < 1 ||
          receipt.failures !== 0 || receipt.skips !== 0)) throw Error('Missing positive local check: ' + name);
  }
  return {packet, plan, seal, planHash: sha(fs.readFileSync(file)), sealHash: sha(fs.readFileSync(path.join(packet, plan.sourceSeal)))};
}
const freeBytes = () => {
  const stat = fs.statfsSync(source);
  return Number(stat.bavail) * Number(stat.bsize);
};
async function command(executable, args, log, env = {}) {
  const allowed = ['/usr/bin/codesign', '/usr/bin/xcrun', '/usr/libexec/PlistBuddy', path.join(sdk, 'bin/cache/dart-sdk/bin/dart')];
  if (!allowed.includes(executable)) throw Error('Unknown executable');
  const environment = {...process.env, ...env, FLUTTER_ROOT: sdk, ZYRA_NO_GIT_ACTIVE: 'pinned-v1'};
  delete environment.ZYRA_FOUNDER_MANUAL_SDK;
  const chunks = [];
  const started = new Date().toISOString();
  const status = await new Promise((resolve, reject) => {
    const child = spawn('/usr/bin/sandbox-exec', ['-f', path.join(tooling, 'no_git.sb'), executable, ...args],
      {cwd: source, env: environment, stdio: ['ignore', 'pipe', 'pipe']});
    for (const stream of ['stdout', 'stderr']) child[stream].on('data', bytes => {
      const text = bytes.toString(); chunks.push({stream, text}); if (log) fs.writeSync(log, text);
    });
    child.on('error', reject);
    child.on('close', (code, signal) => resolve({code, signal}));
  });
  const result = {command: [executable, ...args], started, finished: new Date().toISOString(), ...status,
    stdout: chunks.filter(c => c.stream === 'stdout').map(c => c.text).join(''),
    stderr: chunks.filter(c => c.stream === 'stderr').map(c => c.text).join('')};
  if (status.code !== 0 || status.signal) throw Error('Protected command failed: ' + executable + ' (' + status.code + ')');
  return result;
}
async function checkIdentity(app, log) {
  await command('/usr/bin/codesign', ['--verify', '--deep', '--strict', app], log);
  const detail = await command('/usr/bin/codesign', ['-d', '--verbose=4', app], log);
  if (!detail.stderr.includes('Authority=' + identity) || !detail.stderr.includes('TeamIdentifier=' + team)) throw Error('Existing Development identity mismatch');
  const plist = await command('/usr/libexec/PlistBuddy', ['-c', 'Print :CFBundleIdentifier', '-c', 'Print :CFBundleDisplayName',
    '-c', 'Print :CFBundleShortVersionString', '-c', 'Print :CFBundleVersion', '-c', 'Print :MinimumOSVersion', path.join(app, 'Info.plist')], log);
  if (plist.stdout.trim() !== 'app.zyraconnect.zyra\nZYRA\n1.0.0\n5\n15.0') throw Error('Main identity/version/OS mismatch');
  const entitlements = await command('/usr/bin/codesign', ['-d', '--entitlements', ':-', app], log);
  return entitlements.stdout;
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
      const expected = context.seal.files[relative] ?? context.plan.nativeInputs[relative];
      if (!expected && !/^\.dart_tool\/(?:flutter_build|hooks_runner|native_assets_builder)\//.test(relative)) {
        throw Error('Unsealed compiler input: ' + relative);
      }
      if (expected && sha(fs.readFileSync(plainFile(absolute))) !== expected) throw Error('Compiler input drift: ' + relative);
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
async function main() {
  const [mode, input, ...unknown] = process.argv.slice(2);
  if (!['inspect', 'build'].includes(mode) || !input || unknown.length) throw Error('Use inspect/build with the exact HOST_PROFILE_PLAN.json; unknown arguments refused');
  const file = path.resolve(input), context = loadPlan(file), measured = verifySdkAndHost();
  const space = freeBytes();
  if (mode === 'inspect') {
    console.log(JSON.stringify({scope: context.plan.scope, sourceChecked: true, hostFiles: 177, hostHash,
      genuineEngineCompatible: true, freeBytes: space, requiredFreeBytes: minFreeBytes,
      buildSpaceReady: space >= minFreeBytes, fullXcodeBuild: 'HELD', installs: 'NOT SUPPORTED'}, null, 2));
    return;
  }
  if (space < minFreeBytes) throw Error('Native payload build held: less than 2 GiB free; no cache deletion performed');
  const root = fs.mkdtempSync(path.join(context.packet, 'HOST_PROFILE.'));
  const products = path.join(root, 'products'), candidate = path.join(root, 'Runner.app');
  fs.mkdirSync(products);
  const fd = fs.openSync(path.join(root, 'BUILD.log'), 'wx');
  const receipt = {schema: 1, started: new Date().toISOString(), scope: context.plan.scope, root, candidate,
    planSha256: context.planHash, sourceSealSha256: context.sealHash, reusedHostSha256: hostHash,
    fullXcodeBuild: false, installExecuted: false, commands: [], success: false};
  try {
    const originalEntitlements = await checkIdentity(host, fd);
    const sdkResult = await command('/usr/bin/xcrun', ['--sdk', 'iphoneos', '--show-sdk-path'], fd);
    receipt.commands.push(sdkResult);
    const sdkRoot = sdkResult.stdout.trim();
    if (!/^\/Applications\/Xcode\.app\/Contents\/Developer\/Platforms\/iPhoneOS\.platform\/Developer\/SDKs\/iPhoneOS[^/]*\.sdk$/.test(sdkRoot)) throw Error('Unexpected iPhone SDK');
    const dart = path.join(sdk, 'bin/cache/dart-sdk/bin/dart');
    // Configuration is intentionally absent: an explicit Flavor already gives
    // the same production Dart flavor, without asking Xcode for package info.
    receipt.commands.push(await command(dart, flutterAssembleArgs(products, root, sdkRoot), fd));
    recheckPlan(file, context); verifySdkAndHost(); verifyRuntimePins(measured.runtimePins);
    receipt.compilerDependencyMarkers = [];
    receipt.compilerInputs = verifyCompilationInputs(root, context, receipt.compilerDependencyMarkers);
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
    await command('/usr/bin/codesign', ['--verify', '--strict', path.join(candidate, 'Frameworks/App.framework')], fd);
    receipt.commands.push(await command('/usr/bin/codesign', ['--force', '--sign', identity, '--timestamp=none',
      '--preserve-metadata=identifier,entitlements,requirements,flags,runtime', candidate], fd));
    if (await checkIdentity(candidate, fd) !== originalEntitlements) throw Error('Native entitlements changed');
    if (sha(fs.readFileSync(path.join(candidate, 'embedded.mobileprovision'))) !== profileHash) throw Error('Embedded profile changed');
    receipt.artifact = assertHostDelta(measured.entries, candidate);
    recheckPlan(file, context); verifySdkAndHost(); verifyRuntimePins(measured.runtimePins);
    verifyWildcardRerunRecords(receipt.compilerDependencyMarkers);
    receipt.runtimePins = measured.runtimePins;
    receipt.success = true;
  } catch (error) {
    receipt.failure = String(error);
  } finally {
    fs.closeSync(fd);
    receipt.finished = new Date().toISOString();
    fs.writeFileSync(path.join(root, 'BUILD.json'), JSON.stringify(receipt, null, 2) + '\n', {flag: 'wx'});
  }
  console.log(JSON.stringify({success: receipt.success, root, candidate: receipt.success ? candidate : null,
    failure: receipt.failure, fullXcodeBuild: false, installExecuted: false}, null, 2));
  if (!receipt.success) process.exitCode = 1;
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(String(error)); process.exitCode = 1; });
}
