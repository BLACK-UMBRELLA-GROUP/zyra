// CoreDevice output can contain device and account information. Keep it in memory.
import {execFile} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {promisify} from 'node:util';

const run = promisify(execFile);
const policy = fileURLToPath(new URL('./no_git.sb', import.meta.url));
const childEnv = {
  HOME: process.env.HOME,
  PATH: '/usr/bin:/bin:/usr/sbin:/sbin',
  DEVELOPER_DIR: '/Applications/Xcode.app/Contents/Developer',
};

class PhoneBlocker extends Error {}

function requireProof(proven, reason) {
  if (!proven) throw new PhoneBlocker(reason);
}

async function coreDevice(args, failure, deviceIdentifier) {
  let response;
  try {
    const {stdout} = await run('/usr/bin/sandbox-exec', [
      '-f', policy, '/usr/bin/xcrun', 'devicectl', ...args,
      '--quiet', '--timeout', '45', '--json-output', '-',
    ], {env: childEnv, timeout: 50_000, maxBuffer: 4 * 1024 * 1024});
    response = JSON.parse(stdout);
  } catch {
    throw new PhoneBlocker(failure);
  }
  const {info, result} = response ?? {};
  requireProof(info?.outcome === 'success' && result && typeof result === 'object', failure);
  requireProof(deviceIdentifier === undefined || result.deviceIdentifier === deviceIdentifier,
    'CoreDevice returned a different device or no device identity.');
  return result;
}

function requireTransport(transport) {
  requireProof(transport === 'wired' || transport === 'wireless',
    'Phone transport must be explicitly wired or wireless.');
}

async function pairedPhone(profileDevices, transport, expectedIdentifier, allowIdleTunnel = false) {
  requireTransport(transport);
  const provisioned = new Set(profileDevices);
  requireProof(provisioned.size > 0 && [...provisioned].every(id => typeof id === 'string' && id),
    'The verified provisioning profile supplied no usable phone list.');
  const {devices} = await coreDevice(['list', 'devices'], 'CoreDevice could not list paired devices.');
  requireProof(Array.isArray(devices), 'CoreDevice returned no device inventory.');
  const phones = devices.filter(device => device?.hardwareProperties?.deviceType === 'iPhone' &&
    provisioned.has(device.hardwareProperties.udid));
  const phone = phones[0];
  const connection = phone?.connectionProperties;
  const connected = connection?.tunnelState === 'connected' ||
    (allowIdleTunnel && transport === 'wireless' && connection?.tunnelState === 'disconnected');
  requireProof(phones.length === 1 && typeof phone?.identifier === 'string' && phone.identifier &&
    connection?.pairingState === 'paired' &&
    connection.transportType === (transport === 'wireless' ? 'localNetwork' : 'wired') && connected,
    transport === 'wireless'
      ? 'Keep the single paired, provisioned iPhone connected wirelessly and unlocked.'
      : 'Connect the single paired, provisioned iPhone by USB and keep it unlocked.');
  requireProof(expectedIdentifier === undefined || phone.identifier === expectedIdentifier,
    'The selected iPhone changed during delivery.');
  return phone;
}

async function checkUnlocked(identifier) {
  const state = await coreDevice(['device', 'info', 'lockState', '--device', identifier],
    'The selected iPhone did not report its current lock state.', identifier);
  requireProof(state.passcodeRequired === false && state.unlockedSinceBoot === true,
    'Unlock the selected iPhone and keep its screen awake.');
}

async function readyPhone(profileDevices, transport, expectedIdentifier) {
  // An idle wireless tunnel can reconnect when the live lock-state query runs.
  // Delivery still requires a connected tunnel for the same phone afterward.
  const phone = await pairedPhone(profileDevices, transport, expectedIdentifier, transport === 'wireless');
  await checkUnlocked(phone.identifier);
  return pairedPhone(profileDevices, transport, phone.identifier);
}

export async function checkVerifiedPhone(profileDevices, {transport = 'wired'} = {}) {
  try {
    await readyPhone(profileDevices, transport);
    return {ready: true, paired: true, wired: transport === 'wired', wireless: transport === 'wireless',
      unlocked: true, transport};
  } catch (error) {
    return {ready: false, blocker: error instanceof PhoneBlocker ? error.message : 'Phone preflight could not be verified.'};
  }
}

async function bundleValue(candidate, field) {
  const {stdout} = await run('/usr/bin/plutil', ['-extract', field, 'raw', '-o', '-', path.join(candidate, 'Info.plist')],
    {env: childEnv, timeout: 5_000, maxBuffer: 4096});
  return stdout.trim();
}

async function captureFrame(identifier, work) {
  try {
    const file = path.join(fs.mkdtempSync(path.join(work, 'first-frame-')), 'first-frame.png');
    await coreDevice(['device', 'capture', 'screenshot', '--device', identifier, '--destination', file],
      'CoreDevice could not capture the first frame.', identifier);
    const png = fs.lstatSync(file);
    if (png.isFile() && png.size > 8 && png.size <= 32 * 1024 * 1024 &&
        fs.readFileSync(file).subarray(0, 8).toString('hex') === '89504e470d0a1a0a') {
      return {captureStatus: 'needs-visual-confirmation', captureFile: file};
    }
  } catch {
    // A screenshot failure must not erase a separately verified install and launch.
  }
  return {captureStatus: 'uncertain'};
}

export async function deliverVerifiedPhone({candidate, bundleIdentifier, profileDevices, work, recheckArtifact,
  transport = 'wired'}) {
  const receipt = {stage: 'artifact', transport, installAttempted: false, installSucceeded: false,
    launchAttempted: false, launchSucceeded: false, postVerified: false, captureStatus: 'not-attempted'};
  try {
    requireTransport(transport);
    requireProof(typeof recheckArtifact === 'function' && path.isAbsolute(candidate) && path.basename(candidate) === 'Runner.app',
      'The exact Runner artifact and its verification callback are required.');
    const scratch = fs.lstatSync(work);
    requireProof(scratch.isDirectory() && scratch.uid === process.getuid() && (scratch.mode & 0o077) === 0,
      'Screenshot capture requires an owner-only scratch directory.');
    requireProof(await recheckArtifact() === true, 'The candidate no longer matches the verified artifact.');
    const [bundle, version, build, executable] = await Promise.all([
      bundleValue(candidate, 'CFBundleIdentifier'), bundleValue(candidate, 'CFBundleShortVersionString'),
      bundleValue(candidate, 'CFBundleVersion'), bundleValue(candidate, 'CFBundleExecutable'),
    ]);
    requireProof(bundle === bundleIdentifier && bundle && version && build && executable === 'Runner',
      'Candidate bundle identity or version could not be verified.');
    receipt.stage = 'install-preflight';
    const phone = await readyPhone(profileDevices, transport);
    const identifier = phone.identifier;
    receipt.stage = 'install';
    receipt.installAttempted = true;
    const installed = await coreDevice(['device', 'install', 'app', '--device', identifier, candidate],
      'CoreDevice did not confirm installation. Do not retry automatically.', identifier);
    const apps = installed.installedApplications;
    const installedURL = apps?.[0]?.installationURL;
    const container = typeof installedURL === 'string' && installedURL.match(
      /^file:\/\/\/private\/var\/containers\/Bundle\/Application\/([0-9A-Fa-f-]{36})\/Runner\.app\/$/)?.[1];
    requireProof(apps?.length === 1 && apps[0].bundleID === bundle && container,
    'The installation receipt did not identify the exact application container.');
    receipt.installSucceeded = true;

    receipt.stage = 'launch-preflight';
    requireProof(await recheckArtifact() === true, 'The candidate no longer matches the verified artifact.');
    await readyPhone(profileDevices, transport, identifier);
    receipt.stage = 'launch';
    receipt.launchAttempted = true;
    const launched = await coreDevice(['device', 'process', 'launch', '--terminate-existing', '--activate', '--device', identifier, bundle],
      'CoreDevice did not confirm launch. The verified installation is recorded separately.', identifier);
    const expectedExecutable = `${installedURL}Runner`;
    const processIdentifier = launched.process?.processIdentifier;
    requireProof(Number.isSafeInteger(processIdentifier) && processIdentifier > 0 &&
      launched.process.executable === expectedExecutable && launched.launchOptions?.activatedWhenStarted === true &&
      launched.launchOptions?.startStopped === false &&
      launched.launchOptions?.user?.active === true, 'The launch receipt did not identify the activated installed app.');
    receipt.launchSucceeded = true;
    Object.assign(receipt, await captureFrame(identifier, work));

    receipt.stage = 'post';
    const [appState, processState] = await Promise.all([
      coreDevice(['device', 'info', 'apps', '--device', identifier, '--bundle-id', bundle],
        'CoreDevice did not confirm the installed app.', identifier),
      coreDevice(['device', 'info', 'processes', '--device', identifier, '--search', container],
        'CoreDevice did not confirm the running process.', identifier),
    ]);
    const installedApp = appState.apps?.[0];
    requireProof(appState.apps?.length === 1 && installedApp?.bundleIdentifier === bundle && installedApp?.url === installedURL &&
      installedApp?.version === version && installedApp?.bundleVersion === build, 'The installed app did not match the verified candidate.');
    requireProof(processState.runningProcesses?.some(process => process.processIdentifier === processIdentifier &&
      process.executable === expectedExecutable), 'The launched process was not present in the verified installed app container.');
    const after = await readyPhone(profileDevices, transport, identifier);
    requireProof(after.deviceProperties?.ddiServicesAvailable === true, 'Developer disk image services were not verified after launch.');
    requireProof(await recheckArtifact() === true, 'The candidate no longer matches the verified artifact.');
    receipt.postVerified = true;
    receipt.stage = 'complete';
  } catch (error) {
    receipt.blocker = error instanceof PhoneBlocker ? error.message : 'Delivery could not verify the current stage.';
  }
  return receipt;
}
