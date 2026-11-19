import test, {afterEach} from 'node:test';
import assert from 'node:assert/strict';
import childProcess from 'node:child_process';
import {syncBuiltinESMExports} from 'node:module';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {promisify} from 'node:util';

const identifier = 'synthetic-coredevice-phone';
const profileDevice = 'synthetic-provisioned-iphone';
const bundle = 'app.example.delivery-fixture';
const installedURL = 'file:///private/var/containers/Bundle/Application/12345678-1234-1234-1234-123456789ABC/Runner.app/';
const processIdentifier = 101;
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aWQAAAABJRU5ErkJggg==', 'base64');
const fixtures = fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), 'zyra-phone-test-'));
let scenario;
const unexpectedCommands = [];

function mockedExecFile() {
  throw Error('The delivery test requires the mocked promise dispatcher.');
}
mockedExecFile[promisify.custom] = async (file, args, options) => {
  try {
    assert.ok(scenario, 'every process request needs an active synthetic scenario');
    assert.equal(options.env.PATH, '/usr/bin:/bin:/usr/sbin:/sbin');
    assert.equal(options.env.DEVELOPER_DIR, '/Applications/Xcode.app/Contents/Developer');
    if (file === '/usr/bin/plutil') {
      assert.deepEqual(args.slice(0, 1), ['-extract']);
      assert.deepEqual(args.slice(2, 5), ['raw', '-o', '-']);
      assert.equal(args[5], path.join(scenario.candidate, 'Info.plist'));
      scenario.events.push(`bundle:${args[1]}`);
      return {stdout: `${scenario.bundleFields[args[1]]}\n`, stderr: ''};
    }
    assert.equal(file, '/usr/bin/sandbox-exec');
    assert.equal(args[0], '-f');
    assert.equal(path.basename(args[1]), 'no_git.sb');
    assert.deepEqual(args.slice(2, 4), ['/usr/bin/xcrun', 'devicectl']);
    assert.deepEqual(args.slice(-5), ['--quiet', '--timeout', '45', '--json-output', '-']);
    assert.equal(options.timeout, 50_000);
    assert.equal(options.maxBuffer, 4 * 1024 * 1024);
  } catch (error) {
    unexpectedCommands.push(error);
    throw error;
  }
  try {
    return {stdout: scenario.respond(args.slice(4, -5)), stderr: ''};
  } catch (error) {
    if (error.code === 'ERR_ASSERTION') unexpectedCommands.push(error);
    throw error;
  }
};

// The production module captures promisify(execFile) at import time. Restore
// the builtin immediately afterward so this test never changes other imports.
const originalExecFile = childProcess.execFile;
let checkVerifiedPhone, deliverVerifiedPhone;
try {
  childProcess.execFile = mockedExecFile;
  syncBuiltinESMExports();
  ({checkVerifiedPhone, deliverVerifiedPhone} = await import('./verified_phone_delivery.mjs'));
} finally {
  childProcess.execFile = originalExecFile;
  syncBuiltinESMExports();
}

afterEach(() => {
  scenario = undefined;
  assert.deepEqual(unexpectedCommands.splice(0), [], 'all subprocess calls must use the synthetic dispatcher');
});

function phone({transport = 'localNetwork', pairing = 'paired', tunnel = 'connected',
  id = identifier, udid = profileDevice, type = 'iPhone', ddi = true} = {}) {
  return {identifier: id, hardwareProperties: {deviceType: type, udid},
    connectionProperties: {transportType: transport, pairingState: pairing, tunnelState: tunnel},
    deviceProperties: {ddiServicesAvailable: ddi}};
}

function valueAfter(args, flag) {
  const index = args.indexOf(flag);
  assert.ok(index >= 0, `missing ${flag}`);
  return args[index + 1];
}

function setScenario({devices = [phone()], inventories, locks, overrides = {},
  failures = [], raw = {}, artifactResults = [true, true, true]} = {}) {
  const root = fs.mkdtempSync(path.join(fixtures, 'case-'));
  const work = path.join(root, 'work');
  const candidate = path.join(root, 'Runner.app');
  fs.mkdirSync(work, {mode: 0o700});
  fs.mkdirSync(candidate, {mode: 0o700});
  const counts = {};
  const events = [];
  const calls = [];
  const bundleFields = {CFBundleIdentifier: bundle, CFBundleShortVersionString: '1.0.0',
    CFBundleVersion: '5', CFBundleExecutable: 'Runner'};
  function next(values, count, fallback) {
    return values ? values[Math.min(count - 1, values.length - 1)] : fallback;
  }
  function respond(args) {
    const command = args.slice(0, 3).join(' ');
    const kind = args[0] === 'list' ? 'inventory' : {
      'device info lockState': 'lock', 'device install app': 'install',
      'device process launch': 'launch', 'device capture screenshot': 'screenshot',
      'device info apps': 'apps', 'device info processes': 'processes',
    }[command];
    assert.ok(kind, `unexpected mocked CoreDevice command ${command}`);
    counts[kind] = (counts[kind] ?? 0) + 1;
    events.push(`${kind}:${counts[kind]}`);
    calls.push({kind, args: [...args]});
    if (failures.includes(kind)) throw Error(`Synthetic ${kind} failure`);
    if (Object.hasOwn(raw, kind)) return raw[kind];
    let result;
    if (kind === 'inventory') {
      result = {devices: next(inventories, counts.inventory, devices)};
    } else {
      assert.equal(valueAfter(args, '--device'), identifier, 'every operation must target the selected phone');
      result = {deviceIdentifier: identifier};
      if (kind === 'lock') {
        Object.assign(result, next(locks, counts.lock, {passcodeRequired: false, unlockedSinceBoot: true}));
      } else if (kind === 'install') {
        assert.equal(args.at(-1), candidate, 'installation must use the verified candidate');
        result.installedApplications = [{bundleID: bundle, installationURL: installedURL}];
      } else if (kind === 'launch') {
        assert.ok(args.includes('--terminate-existing'));
        assert.ok(args.includes('--activate'));
        assert.equal(args.at(-1), bundle);
        result.process = {processIdentifier, executable: `${installedURL}Runner`};
        result.launchOptions = {activatedWhenStarted: true, startStopped: false, user: {active: true}};
      } else if (kind === 'screenshot') {
        fs.writeFileSync(valueAfter(args, '--destination'), png);
      } else if (kind === 'apps') {
        assert.equal(valueAfter(args, '--bundle-id'), bundle);
        result.apps = [{bundleIdentifier: bundle, url: installedURL, version: '1.0.0', bundleVersion: '5'}];
      } else if (kind === 'processes') {
        assert.equal(valueAfter(args, '--search'), '12345678-1234-1234-1234-123456789ABC');
        result.runningProcesses = [{processIdentifier, executable: `${installedURL}Runner`}];
      }
    }
    Object.assign(result, overrides[kind]);
    return JSON.stringify({info: {outcome: 'success'}, result});
  }
  async function recheckArtifact() {
    counts.artifact = (counts.artifact ?? 0) + 1;
    events.push(`artifact:${counts.artifact}`);
    return artifactResults[Math.min(counts.artifact - 1, artifactResults.length - 1)];
  }
  scenario = {candidate, work, counts, events, calls, bundleFields, respond, recheckArtifact};
  return scenario;
}

async function deliver(options = {}) {
  return deliverVerifiedPhone({candidate: scenario.candidate, bundleIdentifier: bundle,
    profileDevices: [profileDevice], work: scenario.work, recheckArtifact: scenario.recheckArtifact,
    transport: 'wireless', ...options});
}

function assertHeld(receipt, stage, {installed = false, launched = false} = {}) {
  assert.equal(receipt.stage, stage);
  assert.equal(receipt.installSucceeded, installed);
  assert.equal(receipt.launchSucceeded, launched);
  assert.equal(receipt.postVerified, false);
  assert.equal(typeof receipt.blocker, 'string');
  assert.ok(receipt.blocker.length > 0);
}

test('readiness defaults to the wired route and refuses a wireless phone', async () => {
  setScenario();
  const denied = await checkVerifiedPhone([profileDevice]);
  assert.equal(denied.ready, false);
  assert.equal(scenario.counts.lock ?? 0, 0);
  setScenario({devices: [phone({transport: 'wired'})]});
  const ready = await checkVerifiedPhone([profileDevice]);
  assert.equal(ready.ready, true);
  assert.equal(ready.wired, true);
  assert.equal(ready.unlocked, true);
  assert.deepEqual(scenario.events, ['inventory:1', 'lock:1', 'inventory:2']);
});

test('explicit wireless readiness requires the sole provisioned paired localNetwork iPhone', async () => {
  setScenario({devices: [phone(), phone({transport: 'wired', id: 'other-wired', udid: 'other-wired-udid'}),
    phone({id: 'unprovisioned', udid: 'other-udid'})]});
  const ready = await checkVerifiedPhone([profileDevice], {transport: 'wireless'});
  assert.deepEqual(ready, {ready: true, paired: true, wired: false, wireless: true,
    unlocked: true, transport: 'wireless'});
  assert.deepEqual(scenario.events, ['inventory:1', 'lock:1', 'inventory:2']);
});

test('a dormant wireless tunnel must reconnect after the live lock probe', async () => {
  setScenario({inventories: [[phone({tunnel: 'disconnected'})], [phone()]]});
  assert.equal((await checkVerifiedPhone([profileDevice], {transport: 'wireless'})).ready, true);
  setScenario({devices: [phone({tunnel: 'disconnected'})]});
  assert.equal((await checkVerifiedPhone([profileDevice], {transport: 'wireless'})).ready, false);
  assert.equal(scenario.counts.lock, 1);
  setScenario({devices: [phone({transport: 'wired', tunnel: 'disconnected'})]});
  assert.equal((await checkVerifiedPhone([profileDevice])).ready, false);
  assert.equal(scenario.counts.lock ?? 0, 0);
});

for (const transport of ['', null, 'automatic', 'localNetwork', 'ethernet']) {
  test(`readiness rejects unsupported transport ${String(transport)} before a subprocess`, async () => {
    setScenario();
    assert.equal((await checkVerifiedPhone([profileDevice], {transport})).ready, false);
    assert.deepEqual(scenario.events, []);
  });
}

for (const profileDevices of [[], [''], [null], [profileDevice, '']]) {
  test(`readiness refuses unusable profile device list ${JSON.stringify(profileDevices)}`, async () => {
    setScenario();
    assert.equal((await checkVerifiedPhone(profileDevices, {transport: 'wireless'})).ready, false);
    assert.deepEqual(scenario.events, []);
  });
}

for (const [label, devices] of [
  ['no phone', []], ['wrong transport', [phone({transport: 'wired'})]],
  ['unpaired phone', [phone({pairing: 'unpaired'})]],
  ['unprovisioned phone', [phone({udid: 'unprovisioned'})]],
  ['wrong device type', [phone({type: 'iPad'})]],
  ['missing identity', [phone({id: ''})]],
  ['two eligible phones', [phone(), phone({id: 'second-phone'})]],
  ['second provisioned wired phone', [phone(), phone({id: 'second-phone', transport: 'wired'})]],
  ['second provisioned unpaired phone', [phone(), phone({id: 'second-phone', pairing: 'unpaired'})]],
]) {
  test(`wireless readiness refuses ${label}`, async () => {
    setScenario({devices});
    assert.equal((await checkVerifiedPhone([profileDevice], {transport: 'wireless'})).ready, false);
  });
}

for (const [label, options] of [
  ['malformed response', {raw: {inventory: 'not json'}}],
  ['unsuccessful response', {raw: {inventory: JSON.stringify({info: {outcome: 'failure'}, result: {devices: [phone()]}})}}],
  ['missing inventory', {overrides: {inventory: {devices: undefined}}}],
  ['locked phone', {locks: [{passcodeRequired: true, unlockedSinceBoot: true}]}],
  ['never unlocked', {locks: [{passcodeRequired: false, unlockedSinceBoot: false}]}],
  ['missing lock proof', {locks: [{}]}],
  ['another phone lock response', {overrides: {lock: {deviceIdentifier: 'other-phone'}}}],
  ['phone changes after unlock', {inventories: [[phone()], [phone({id: 'replacement-phone'})]]}],
  ['phone disconnects after unlock', {inventories: [[phone()], [phone({tunnel: 'disconnected'})]]}],
  ['phone loses pairing after unlock', {inventories: [[phone()], [phone({pairing: 'unpaired'})]]}],
  ['phone changes transport after unlock', {inventories: [[phone()], [phone({transport: 'wired'})]]}],
  ['phone loses provisioning after unlock', {inventories: [[phone()], [phone({udid: 'other-udid'})]]}],
]) {
  test(`wireless readiness fails closed on ${label}`, async () => {
    setScenario(options);
    assert.equal((await checkVerifiedPhone([profileDevice], {transport: 'wireless'})).ready, false);
  });
}

test('wireless delivery verifies the exact artifact and live phone at every transition', async () => {
  setScenario();
  const receipt = await deliver();
  assert.equal(receipt.transport, 'wireless');
  assert.equal(receipt.stage, 'complete');
  assert.equal(receipt.installSucceeded, true);
  assert.equal(receipt.launchSucceeded, true);
  assert.equal(receipt.postVerified, true);
  assert.equal(receipt.captureStatus, 'needs-visual-confirmation');
  assert.deepEqual(fs.readFileSync(receipt.captureFile), png);
  assert.deepEqual(scenario.events, ['artifact:1', 'bundle:CFBundleIdentifier',
    'bundle:CFBundleShortVersionString', 'bundle:CFBundleVersion', 'bundle:CFBundleExecutable',
    'inventory:1', 'lock:1', 'inventory:2', 'install:1', 'artifact:2',
    'inventory:3', 'lock:2', 'inventory:4', 'launch:1', 'screenshot:1',
    'apps:1', 'processes:1', 'inventory:5', 'lock:3', 'inventory:6', 'artifact:3']);
});

test('delivery preserves wired as the default transport', async () => {
  setScenario();
  const denied = await deliver({transport: undefined});
  assertHeld(denied, 'install-preflight');
  assert.equal(denied.installAttempted, false);
  setScenario({devices: [phone({transport: 'wired'})]});
  const ready = await deliver({transport: undefined});
  assert.equal(ready.postVerified, true);
  assert.equal(ready.transport, 'wired');
});

test('delivery rejects invalid transport before reading or installing the app', async () => {
  setScenario();
  const receipt = await deliver({transport: 'localNetwork'});
  assert.equal(receipt.postVerified, false);
  assert.equal(receipt.installAttempted, false);
  assert.deepEqual(scenario.events, []);
});

for (const [label, change] of [
  ['relative candidate', {candidate: 'Runner.app'}],
  ['another application', {candidate: '/synthetic/Other.app'}],
  ['missing artifact verifier', {recheckArtifact: undefined}],
]) {
  test(`delivery refuses ${label}`, async () => {
    setScenario();
    assertHeld(await deliver(change), 'artifact');
    assert.deepEqual(scenario.events, []);
  });
}

test('delivery refuses a scratch directory that other users can access', async () => {
  setScenario();
  fs.chmodSync(scenario.work, 0o755);
  assertHeld(await deliver(), 'artifact');
  assert.deepEqual(scenario.events, []);
});

for (const [label, field, value] of [
  ['bundle mismatch', 'CFBundleIdentifier', 'app.example.other'],
  ['missing version', 'CFBundleShortVersionString', ''],
  ['missing build', 'CFBundleVersion', ''],
  ['wrong executable', 'CFBundleExecutable', 'Other'],
]) {
  test(`delivery refuses ${label} before phone mutation`, async () => {
    setScenario();
    scenario.bundleFields[field] = value;
    const receipt = await deliver();
    assertHeld(receipt, 'artifact');
    assert.equal(receipt.installAttempted, false);
    assert.equal(scenario.counts.inventory ?? 0, 0);
  });
}

for (const [label, artifactResults, stage, installed, launched] of [
  ['before install', [false], 'artifact', false, false],
  ['before launch', [true, false], 'launch-preflight', true, false],
  ['after launch', [true, true, false], 'post', true, true],
]) {
  test(`artifact drift ${label} stops delivery`, async () => {
    setScenario({artifactResults});
    assertHeld(await deliver(), stage, {installed, launched});
    assert.equal(scenario.counts.install ?? 0, installed ? 1 : 0);
    assert.equal(scenario.counts.launch ?? 0, launched ? 1 : 0);
  });
}

for (const [label, locks, stage, installed, launched] of [
  ['before install', [{passcodeRequired: true, unlockedSinceBoot: true}], 'install-preflight', false, false],
  ['before launch', [{passcodeRequired: false, unlockedSinceBoot: true},
    {passcodeRequired: true, unlockedSinceBoot: true}], 'launch-preflight', true, false],
  ['during postcheck', [{passcodeRequired: false, unlockedSinceBoot: true},
    {passcodeRequired: false, unlockedSinceBoot: true}, {passcodeRequired: true, unlockedSinceBoot: true}], 'post', true, true],
]) {
  test(`a phone that locks ${label} stops delivery`, async () => {
    setScenario({locks});
    assertHeld(await deliver(), stage, {installed, launched});
    assert.equal(scenario.counts.install ?? 0, installed ? 1 : 0);
    assert.equal(scenario.counts.launch ?? 0, launched ? 1 : 0);
  });
}

for (const [label, inventories, stage, launched] of [
  ['before launch', [[phone()], [phone()], [phone({id: 'replacement'})]], 'launch-preflight', false],
  ['after launch', [[phone()], [phone()], [phone()], [phone()], [phone({id: 'replacement'})]], 'post', true],
]) {
  test(`a substituted phone ${label} is refused`, async () => {
    setScenario({inventories});
    assertHeld(await deliver(), stage, {installed: true, launched});
    assert.equal(scenario.counts.launch ?? 0, launched ? 1 : 0);
  });
}

test('failed installation is recorded once and never launches or retries', async () => {
  setScenario({failures: ['install']});
  const receipt = await deliver();
  assertHeld(receipt, 'install');
  assert.equal(receipt.installAttempted, true);
  assert.equal(receipt.launchAttempted, false);
  assert.equal(scenario.counts.install, 1);
  assert.equal(scenario.counts.launch ?? 0, 0);
});

for (const [label, install] of [
  ['no installed app', {installedApplications: []}],
  ['wrong bundle', {installedApplications: [{bundleID: 'app.other', installationURL: installedURL}]}],
  ['noncanonical container', {installedApplications: [{bundleID: bundle, installationURL: 'file:///tmp/Runner.app/'}]}],
  ['extra app receipt', {installedApplications: [{bundleID: bundle, installationURL: installedURL}, {bundleID: bundle, installationURL: installedURL}]}],
  ['wrong device', {deviceIdentifier: 'other-phone'}],
]) {
  test(`installation receipt rejects ${label}`, async () => {
    setScenario({overrides: {install}});
    assertHeld(await deliver(), 'install');
    assert.equal(scenario.counts.install, 1);
    assert.equal(scenario.counts.launch ?? 0, 0);
  });
}

test('launch failure preserves the verified install and never retries', async () => {
  setScenario({failures: ['launch']});
  const receipt = await deliver();
  assertHeld(receipt, 'launch', {installed: true});
  assert.equal(receipt.launchAttempted, true);
  assert.equal(scenario.counts.launch, 1);
  assert.equal(scenario.counts.install, 1);
});

for (const [label, launch] of [
  ['invalid process id', {process: {processIdentifier: 0, executable: `${installedURL}Runner`}}],
  ['another executable', {process: {processIdentifier, executable: '/tmp/Runner'}}],
  ['unactivated launch', {launchOptions: {activatedWhenStarted: false, startStopped: false, user: {active: true}}}],
  ['stopped launch', {launchOptions: {activatedWhenStarted: true, startStopped: true, user: {active: true}}}],
  ['inactive user', {launchOptions: {activatedWhenStarted: true, startStopped: false, user: {active: false}}}],
  ['wrong device', {deviceIdentifier: 'other-phone'}],
]) {
  test(`launch receipt rejects ${label}`, async () => {
    setScenario({overrides: {launch}});
    assertHeld(await deliver(), 'launch', {installed: true});
    assert.equal(scenario.counts.launch, 1);
    assert.equal(scenario.counts.apps ?? 0, 0);
  });
}

for (const [label, overrides] of [
  ['another installed app', {apps: {apps: [{bundleIdentifier: 'app.other', url: installedURL, version: '1.0.0', bundleVersion: '5'}]}}],
  ['another installed version', {apps: {apps: [{bundleIdentifier: bundle, url: installedURL, version: '2.0.0', bundleVersion: '5'}]}}],
  ['another installed build', {apps: {apps: [{bundleIdentifier: bundle, url: installedURL, version: '1.0.0', bundleVersion: '6'}]}}],
  ['another installed container', {apps: {apps: [{bundleIdentifier: bundle, url: `${installedURL}other/`, version: '1.0.0', bundleVersion: '5'}]}}],
  ['missing process', {processes: {runningProcesses: []}}],
  ['another process executable', {processes: {runningProcesses: [{processIdentifier, executable: '/tmp/Runner'}]}}],
  ['another process id', {processes: {runningProcesses: [{processIdentifier: 102, executable: `${installedURL}Runner`}]}}],
  ['wrong app response device', {apps: {deviceIdentifier: 'other-phone'}}],
]) {
  test(`postcheck refuses ${label}`, async () => {
    setScenario({overrides});
    assertHeld(await deliver(), 'post', {installed: true, launched: true});
  });
}

test('postcheck requires developer disk image services on the same ready phone', async () => {
  setScenario({devices: [phone({ddi: false})]});
  assertHeld(await deliver(), 'post', {installed: true, launched: true});
});

test('unavailable screenshot preserves separately verified install and launch evidence', async () => {
  setScenario({failures: ['screenshot']});
  const receipt = await deliver();
  assert.equal(receipt.postVerified, true);
  assert.equal(receipt.installSucceeded, true);
  assert.equal(receipt.launchSucceeded, true);
  assert.equal(receipt.captureStatus, 'uncertain');
});
