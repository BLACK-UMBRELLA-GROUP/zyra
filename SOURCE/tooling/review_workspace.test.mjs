import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createReviewWorkspace, readCommitSha, writeBuildEvidence} from './review_workspace.mjs';
import {prepareLocalIosOverlay, verifyLocalIosOverlay} from './local_ios_overlay.mjs';

function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'zyra-review-evidence-'));
  const source = path.join(root, 'ZYRA/SOURCE');
  const packet = path.join(root, 'ZYRA/REPORTS/EVIDENCE/OA305_NO_GIT_OPTION2_DELIVERY_fixture');
  fs.mkdirSync(source, {recursive: true});
  fs.mkdirSync(packet, {recursive: true});
  return {root, source, packet};
}
function write(file, text) {
  fs.mkdirSync(path.dirname(file), {recursive: true});
  fs.writeFileSync(file, text);
}
const metadata = {commitSha: 'a'.repeat(40), flutterVersion: '3.44.2', buildMode: 'profile',
  target: 'ios-arm64 / lib/main.dart / production'};
const times = {started: '2026-10-27T12:00:00.000Z', finished: '2026-10-27T12:00:01.000Z'};

test('host products stay in build cache and repeated evidence export replaces text only', () => {
  const {source, packet} = fixture();
  const root = createReviewWorkspace(source, packet, 'HOST_PROFILE');
  write(path.join(root, 'products/App.framework/App'), 'synthetic compiled fixture');
  write(path.join(root, 'Runner.app/Runner'), 'synthetic compiled fixture');
  const receipt = {root, ...times, success: true, commands: [], artifact: {entries: {'Runner': {bytes: 26}}}};
  write(path.join(root, 'BUILD.json'), JSON.stringify(receipt, null, 2) + '\n');
  // A valid tiny PNG is synthetic review evidence, not a real application capture.
  write(path.join(packet, 'screen.png'), Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWQAAAABJRU5ErkJggg==', 'base64'));
  write(path.join(packet, 'REVIEW.json'), JSON.stringify({fixture: true}));
  writeBuildEvidence(packet, receipt, metadata);
  const latest = {...receipt, success: false, finished: '2026-10-27T12:00:02.000Z'};
  write(path.join(root, 'BUILD.json'), JSON.stringify(latest, null, 2) + '\n');
  writeBuildEvidence(packet, latest, metadata);
  assert.deepEqual(fs.readdirSync(packet).sort(), ['BUILD.json', 'REVIEW.json', 'screen.png']);
  const exported = JSON.parse(fs.readFileSync(path.join(packet, 'BUILD.json'), 'utf8'));
  assert.equal(exported.success, false, 'a failed final attempt must remain failed');
  assert.equal(exported.commitSha, metadata.commitSha);
  assert.equal(exported.completedAt, latest.finished);
  assert.equal(exported.buildReceipt, path.join(root, 'BUILD.json'));
  assert.equal(Object.hasOwn(exported, 'commands'), false);
  assert.ok(fs.existsSync(path.join(root, 'Runner.app/Runner')));
  assert.throws(() => createReviewWorkspace(source, packet, 'HOST_PROFILE'), /EEXIST/,
    'another build must not silently append an app copy or reuse stale products');
  assert.deepEqual(fs.readdirSync(path.dirname(root)), ['HOST_PROFILE']);
  const bytes = fs.readdirSync(packet).reduce((sum, name) => sum + fs.statSync(path.join(packet, name)).size, 0);
  assert.ok(bytes < 9 * 1024 ** 2);
  console.log(JSON.stringify({fixtureEvidence: packet, bytes, fixtureOnly: true}));
});

test('workspace ownership and linked build/evidence destinations fail closed', () => {
  const {root, source, packet} = fixture();
  assert.throws(() => createReviewWorkspace(source, path.join(packet, 'nested'), 'HOST_PROFILE'), /Unowned/);
  assert.throws(() => createReviewWorkspace(source, packet, '../REPORTS'), /Unowned/);
  fs.symlinkSync(packet, path.join(source, 'build'));
  assert.throws(() => createReviewWorkspace(source, packet, 'HOST_PROFILE'), /link/);
  const receipt = {root, ...times, success: true};
  const unrelated = path.join(root, 'unrelated.json');
  write(unrelated, 'preserve');
  fs.symlinkSync(unrelated, path.join(packet, 'BUILD.json'));
  assert.throws(() => writeBuildEvidence(packet, receipt, metadata));
  assert.equal(fs.readFileSync(unrelated, 'utf8'), 'preserve');
  assert.throws(() => writeBuildEvidence(packet, receipt, {...metadata, commitSha: 'unknown'}), /Incomplete/);
  assert.throws(() => writeBuildEvidence(packet, {...receipt, finished: '2026-10-26'}, metadata), /Incomplete/);
});

test('commit SHA is read from repository metadata without invoking git', () => {
  const {root} = fixture(), repository = path.join(root, 'repository');
  const sha = 'b'.repeat(40);
  write(path.join(repository, '.git/HEAD'), 'ref: refs/heads/main\n');
  write(path.join(repository, '.git/refs/heads/main'), sha + '\n');
  assert.equal(readCommitSha(repository), sha);
  write(path.join(repository, '.git/HEAD'), 'ref: refs/heads/packed\n');
  write(path.join(repository, '.git/packed-refs'), '# pack-refs with: peeled\n' + sha + ' refs/heads/packed\n');
  assert.equal(readCommitSha(repository), sha);
  write(path.join(repository, '.git/HEAD'), sha + '\n');
  assert.equal(readCommitSha(repository), sha);
  write(path.join(repository, '.git/HEAD'), 'ref: refs/../../outside\n');
  assert.throws(() => readCommitSha(repository), /Cannot identify/);
});

test('offline overlay producer copies source outside evidence and verifies new path ownership', () => {
  const {source, packet} = fixture();
  const pins = Array.from({length: 8}, (_, index) => ({identity: 'p' + index, kind: 'remoteSourceControl',
    location: 'https://example.invalid/p' + index + '.git', state: {revision: 'c'.repeat(40)}}));
  write(path.join(source, 'ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved'), JSON.stringify({pins}));
  for (const pin of pins) write(path.join(source, 'build/ios/SourcePackages/checkouts', pin.identity, 'Package.swift'),
    'import PackageDescription\nlet package = Package(name: "' + pin.identity + '", targets: [.target(name: "' + pin.identity + '")])\n');
  write(path.join(source, 'ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift'),
    'import PackageDescription\nlet package = Package(name: "generated", dependencies: [.package(name: "google_sign_in_ios", path: "../.packages/google_sign_in_ios-6.3.0")], targets: [.target(name: "generated")])\n');
  write(path.join(source, 'ios/Flutter/ephemeral/Packages/.packages/google_sign_in_ios-6.3.0/Package.swift'),
    'import PackageDescription\nlet package = Package(name: "google", targets: [.target(name: "google")])\n');
  write(path.join(source, 'ios/Runner.xcodeproj/project.pbxproj'),
    'relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;\n');
  for (const name of ['zyra_xcode_backend.sh', 'zyra_xcode_backend.dart', 'no_git.sb', 'sdk_pins.json']) {
    write(path.join(source, 'tooling', name), 'synthetic source fixture\n');
  }
  const result = prepareLocalIosOverlay(source, packet, 'LOCAL_IOS_PROJECTION');
  assert.equal(result.root, path.join(source, 'build/review-work', path.basename(packet), 'LOCAL_IOS_PROJECTION'));
  assert.deepEqual(fs.readdirSync(packet), ['LOCAL_IOS_PROJECTION.json']);
  const pointer = JSON.parse(fs.readFileSync(path.join(packet, 'LOCAL_IOS_PROJECTION.json'), 'utf8'));
  assert.equal(pointer.schema, 4);
  assert.equal(Object.hasOwn(pointer, 'plugin'), false, 'source manifests stay in the build receipt');
  assert.equal(Object.hasOwn(pointer, 'localOverlayFiles'), false);
  assert.equal(verifyLocalIosOverlay(source, path.join(packet, 'LOCAL_IOS_PROJECTION.json')).root, result.root);
  assert.throws(() => prepareLocalIosOverlay(source, packet, 'LOCAL_IOS_PROJECTION'), /immutable/);
  const receiptFile = path.join(packet, 'LOCAL_IOS_PROJECTION.json');
  const receipt = JSON.parse(fs.readFileSync(receiptFile, 'utf8'));
  receipt.root = path.join(packet, 'LOCAL_IOS.old');
  write(receiptFile, JSON.stringify(receipt));
  assert.throws(() => verifyLocalIosOverlay(source, receiptFile), /escapes build cache/);
});
