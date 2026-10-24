import test from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {machoPayload, sameNativePayload, validSourcePath, requiredNativeInputs, flutterAssembleArgs, isWildcardRerunMarker, classifyCompilerDependency, verifyWildcardRerunRecords, singleArm64FatAsset, sameSingleArm64FatAssetPayload, sameUnusedNativeAssetRequirements, validateAotFrameworkPayload} from './verified_host_profile.mjs';

const source = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const marker = path.join(source, 'DOES_NOT_EXIST_RERUN_FOR_WILDCARD77885537');

function fixture(signatureSize = 256) {
  const bytes = Buffer.alloc(1024 + signatureSize);
  bytes.writeUInt32LE(0xfeedfacf, 0);
  bytes.writeUInt32LE(0x0100000c, 4);
  bytes.writeUInt32LE(3, 16);
  bytes.writeUInt32LE(112, 20);
  const segment = 32;
  bytes.writeUInt32LE(0x19, segment);
  bytes.writeUInt32LE(72, segment + 4);
  bytes.write('__LINKEDIT', segment + 8);
  bytes.writeBigUInt64LE(16384n, segment + 32);
  bytes.writeBigUInt64LE(512n, segment + 40);
  bytes.writeBigUInt64LE(BigInt(bytes.length - 512), segment + 48);
  const signature = 104;
  bytes.writeUInt32LE(0x1d, signature);
  bytes.writeUInt32LE(16, signature + 4);
  bytes.writeUInt32LE(1024, signature + 8);
  bytes.writeUInt32LE(signatureSize, signature + 12);
  bytes.writeUInt32LE(0x1b, 120);
  bytes.writeUInt32LE(24, 124);
  bytes.fill(7, 128, 144);
  bytes.fill(11, 200, 500);
  bytes.fill(3, 1024);
  return bytes;
}
function fatFixture(signatureSize = 256) {
  const slice = fixture(signatureSize), offset = 16384, bytes = Buffer.alloc(offset + slice.length);
  bytes.writeUInt32BE(0xcafebabe, 0);
  bytes.writeUInt32BE(1, 4);
  bytes.writeUInt32BE(0x0100000c, 8);
  bytes.writeUInt32BE(0, 12);
  bytes.writeUInt32BE(offset, 16);
  bytes.writeUInt32BE(slice.length, 20);
  bytes.writeUInt32BE(14, 24);
  slice.copy(bytes, offset);
  return bytes;
}

test('only signing bytes and validated tail geometry may change', () => {
  const original = fixture(), signed = fixture(384);
  signed.fill(99, 1024);
  assert.equal(sameNativePayload(original, signed), true);
  assert.equal(machoPayload(original).signatureOffset, 1024);
});
test('even one native code/metadata byte change is refused', () => {
  const original = fixture(), changed = fixture();
  changed[210] ^= 1;
  assert.equal(sameNativePayload(original, changed), false);
  changed[210] ^= 1;
  changed[128] ^= 1;
  assert.equal(sameNativePayload(original, changed), false);
});
test('non-arm64, malformed commands and non-final signature are refused', () => {
  const nonArm = fixture(); nonArm.writeUInt32LE(7, 4);
  assert.throws(() => machoPayload(nonArm), /arm64/);
  const malformed = fixture(); malformed.writeUInt32LE(5000, 36);
  assert.throws(() => machoPayload(malformed), /load command/);
  assert.throws(() => machoPayload(Buffer.concat([fixture(), Buffer.from([0])])), /signature/);
});
test('source input guard refuses traversal, metadata and private directories', () => {
  for (const name of ['../secret', '/tmp/secret', 'lib/../secret', 'lib/.git/config',
    'lib/PRIVATE — API KEYS — DO NOT SYNC/key', 'lib\\secret', '.env', 'ios/unknown.conf']) {
    assert.equal(validSourcePath(name), false, name);
  }
  for (const name of ['lib/main.dart', 'assets/fonts/Poppins-Regular.ttf', 'test/example_test.dart',
    ...requiredNativeInputs]) assert.equal(validSourcePath(name), true, name);
});
test('genuine assemble receives encoded exact Founder defines and no Xcode configuration', () => {
  const args = flutterAssembleArgs('/owned/products', '/owned', '/Applications/Xcode.app/iPhoneOS.sdk');
  const encoded = args.find(value => value.startsWith('--DartDefines='));
  assert.deepEqual(encoded.slice('--DartDefines='.length).split(',').map(value => Buffer.from(value, 'base64').toString()),
    ['ZYRA_INTERNAL_FOUNDER_ACCESS=true', 'ZYRA_INTERNAL_FOUNDER_UUID=dfcbd00d-bc22-4d6e-999b-3a9264cf3510']);
  assert.equal(args.some(value => value.startsWith('--dart-define')), false);
  assert.equal(args.some(value => value.includes('Configuration=')), false);
  assert.ok(args.includes('-dFlavor=production'));
  assert.ok(args.includes('-dBuildMode=profile'));
  assert.ok(args.includes('profile_ios_bundle_flutter_assets'));
});
test('only the exact absent source-root wildcard marker is a phantom dependency', () => {
  assert.equal(isWildcardRerunMarker(marker, () => false), true);
  assert.equal(isWildcardRerunMarker(marker, () => true), false,
    'a real file or dangling symlink must not be ignored');
  assert.equal(isWildcardRerunMarker(marker), true, 'observed genuine marker remains absent');
});
test('relative traversal nested malformed and nonnumeric marker lookalikes stay denied', () => {
  for (const input of ['DOES_NOT_EXIST_RERUN_FOR_WILDCARD77885537',
    source + '/lib/../DOES_NOT_EXIST_RERUN_FOR_WILDCARD77885537',
    source + '/lib/DOES_NOT_EXIST_RERUN_FOR_WILDCARD77885537',
    source + '/DOES_NOT_EXIST_RERUN_FOR_WILDCARD', source + '/DOES_NOT_EXIST_RERUN_FOR_WILDCARDabc',
    source + '/DOES_NOT_EXIST_RERUN_FOR_WILDCARD12345678901',
    source + '/DOES_NOT_EXIST_RERUN_FOR_WILDCARD1.dart',
    source + '/PRIVATE — API KEYS — DO NOT SYNC/DOES_NOT_EXIST_RERUN_FOR_WILDCARD1',
    '/tmp/DOES_NOT_EXIST_RERUN_FOR_WILDCARD1', null]) {
    assert.equal(isWildcardRerunMarker(input, () => false), false, String(input));
  }
});
test('one phantom is recorded but a second and filesystem uncertainty fail closed', () => {
  const records = [];
  assert.equal(classifyCompilerDependency(marker, records, () => false), true);
  assert.equal(records.length, 1);
  assert.equal(records[0].input, marker);
  assert.match(records[0].producerSha256, /^[a-f0-9]{64}$/);
  assert.equal(classifyCompilerDependency(source + '/unknown_missing.dart', records, () => false), false);
  assert.equal(classifyCompilerDependency(marker, records, () => true), false);
  assert.throws(() => classifyCompilerDependency(marker, records, () => false), /Multiple/);
  assert.throws(() => isWildcardRerunMarker(marker, () => { throw Error('EACCES'); }), /EACCES/);
});
test('recorded phantom must still be absent with the same pinned producer before signing', () => {
  const records = [];
  classifyCompilerDependency(marker, records, () => false);
  verifyWildcardRerunRecords(records, () => false);
  verifyWildcardRerunRecords([]);
  assert.throws(() => verifyWildcardRerunRecords(records, () => true), /no longer absent/);
  assert.throws(() => verifyWildcardRerunRecords([{...records[0], producerSha256: '0'.repeat(64)}]), /changed/);
  assert.throws(() => verifyWildcardRerunRecords([{...records[0], input: source + '/unknown.dart'}]), /changed/);
  assert.throws(() => verifyWildcardRerunRecords([records[0], records[0]]), /changed/);
  assert.throws(() => verifyWildcardRerunRecords(null), /changed/);
});
test('measured single-arm64 FAT container permits only contained signing changes', () => {
  const before = fatFixture(), after = fatFixture(384);
  after.fill(99, 16384 + 1024);
  assert.equal(singleArm64FatAsset(before).slice.length, fixture().length);
  assert.equal(sameSingleArm64FatAssetPayload(before, after), true);
  assert.throws(() => machoPayload(before), /thin arm64/, 'thin engine guard is not widened');
});
test('new Dart AOT validates its contained single-arm64 FAT without changing either buffer', () => {
  const bytes = fatFixture(), original = Buffer.from(bytes);
  assert.deepEqual(validateAotFrameworkPayload(bytes), machoPayload(fixture()));
  assert.equal(bytes.equals(original), true);
  assert.throws(() => machoPayload(bytes), /thin arm64/,
    'native Runner and engine validator is not broadened');
  assert.throws(() => validateAotFrameworkPayload(fixture()), /single arm64/,
    'the observed AOT form is required, not a permissive fallback');
});
test('Dart AOT rejects extra architecture trailing bytes bad containment and unsigned slice', () => {
  for (const [offset, value] of [[4, 2], [8, 7], [12, 1], [16, 4], [20, 999999], [24, 31]]) {
    const bad = fatFixture(); bad.writeUInt32BE(value, offset);
    assert.throws(() => validateAotFrameworkPayload(bad));
  }
  assert.throws(() => validateAotFrameworkPayload(Buffer.concat([fatFixture(), Buffer.from([0])])));
  const unsigned = fatFixture(); unsigned.writeUInt32LE(0x2b, 16384 + 104);
  assert.throws(() => validateAotFrameworkPayload(unsigned), /signature/);
  const nonArm = fatFixture(); nonArm.writeUInt32LE(7, 16384 + 4);
  assert.throws(() => validateAotFrameworkPayload(nonArm), /architecture/);
});
test('FAT code UUID padding and architecture changes remain refused', () => {
  for (const offset of [16384 + 210, 16384 + 128, 1000]) {
    const changed = fatFixture(); changed[offset] ^= 1;
    assert.equal(sameSingleArm64FatAssetPayload(fatFixture(), changed), false);
  }
  for (const [offset, value] of [[4, 2], [8, 7], [12, 1], [16, 4], [20, 999999], [24, 31]]) {
    const changed = fatFixture(); changed.writeUInt32BE(value, offset);
    assert.throws(() => singleArm64FatAsset(changed), /FAT|architecture/);
  }
  const mismatch = fatFixture(); mismatch.writeUInt32LE(1, 16384 + 8);
  assert.throws(() => singleArm64FatAsset(mismatch), /architecture/);
  assert.throws(() => singleArm64FatAsset(Buffer.concat([fatFixture(), Buffer.from([0])])), /Uncontained/);
});
test('only unused native requirement comparison permits a fresh link UUID without mutating bytes', () => {
  const before = fatFixture(), after = fatFixture(), originalBefore = Buffer.from(before), originalAfter = Buffer.from(after);
  after[16384 + 128] ^= 1;
  const changedAfter = Buffer.from(after);
  assert.equal(sameUnusedNativeAssetRequirements(before, after), true);
  assert.equal(sameSingleArm64FatAssetPayload(before, after), false);
  assert.equal(sameNativePayload(singleArm64FatAsset(before).slice, singleArm64FatAsset(after).slice), false);
  assert.equal(before.equals(originalBefore), true);
  assert.equal(after.equals(changedAfter), true);
  assert.notDeepEqual(after, originalAfter);
});
test('unused asset requirements still refuse changed code metadata padding and multiple architectures', () => {
  for (const offset of [16384 + 210, 16384 + 12, 1000]) {
    const changed = fatFixture(); changed[offset] ^= 1;
    assert.equal(sameUnusedNativeAssetRequirements(fatFixture(), changed), false);
  }
  const multiple = fatFixture(); multiple.writeUInt32BE(2, 4);
  assert.throws(() => sameUnusedNativeAssetRequirements(fatFixture(), multiple), /single arm64/);
  assert.equal(sameUnusedNativeAssetRequirements(fatFixture(), fatFixture(384)), false,
    'even signing geometry must match for unused requirement evidence');
});
test('unused requirement UUID mask rejects missing malformed and duplicate commands', () => {
  const malformed = fatFixture(); malformed.writeUInt32LE(12, 16384 + 124);
  assert.throws(() => sameUnusedNativeAssetRequirements(fatFixture(), malformed));
  const missing = fatFixture(); missing.writeUInt32LE(0x2b, 16384 + 120);
  assert.throws(() => sameUnusedNativeAssetRequirements(fatFixture(), missing));
  for (const size of [16, 32]) {
    const badSize = fatFixture();
    badSize.writeUInt32LE(72 + 16 + size, 16384 + 20);
    badSize.writeUInt32LE(size, 16384 + 124);
    assert.doesNotThrow(() => machoPayload(singleArm64FatAsset(badSize).slice));
    assert.throws(() => sameUnusedNativeAssetRequirements(fatFixture(), badSize), /Ambiguous/);
  }
  // The older thin parser accepts this otherwise-contained duplicate UUID.
  // The requirement helper must independently deny the ambiguous mask.
  const duplicate = fatFixture();
  duplicate.writeUInt32LE(4, 16384 + 16);
  duplicate.writeUInt32LE(136, 16384 + 20);
  duplicate.copy(duplicate, 16384 + 144, 16384 + 120, 16384 + 144);
  assert.doesNotThrow(() => machoPayload(singleArm64FatAsset(duplicate).slice));
  assert.throws(() => sameUnusedNativeAssetRequirements(fatFixture(), duplicate), /Ambiguous/);
});
