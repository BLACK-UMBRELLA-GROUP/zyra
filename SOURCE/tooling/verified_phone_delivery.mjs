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

async function wiredPhone(profileDevices, expectedIdentifier) {
  const provisioned = new Set(profileDevices);
  requireProof(provisioned.size > 0 && [...provisioned].every(id => typeof id === 'string' && id),
    'The verified provisioning profile supplied no usable phone list.');
  const {devices} = await coreDevice(['list', 'devices'], 'CoreDevice could not list paired devices.');
  requireProof(Array.isArray(devices), 'CoreDevice returned no device inventory.');
  const wired = devices.filter(device => device?.hardwareProperties?.deviceType === 'iPhone' &&
    provisioned.has(device.hardwareProperties.udid) && device.connectionProperties?.pairingState === 'paired' &&
    device.connectionProperties.transportType === 'wired' && device.connectionProperties.tunnelState === 'connected');
  requireProof(wired.length === 1 && typeof wired[0].identifier === 'string' && wired[0].identifier,
    'Connect the single paired, provisioned iPhone by USB and keep it unlocked.');
  requireProof(expectedIdentifier === undefined || wired[0].identifier === expectedIdentifier,
    'The wired iPhone changed during delivery.');
  return wired[0];
}

async function checkUnlocked(identifier) {
  const state = await coreDevice(['device', 'info', 'lockState', '--device', identifier],
    'The wired iPhone did not report its current lock state.', identifier);
  requireProof(state.passcodeRequired === false && state.unlockedSinceBoot === true,
    'Unlock the wired iPhone and keep its screen awake.');
}

export async function checkVerifiedPhone(profileDevices) {
  try {
    const phone = await wiredPhone(profileDevices);
    await checkUnlocked(phone.identifier);
    return {ready: true, paired: true, wired: true, unlocked: true};
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

export async function deliverVerifiedPhone({candidate, bundleIdentifier, profileDevices, work, recheckArtifact}) {
  const receipt = {stage: 'artifact', installAttempted: false, installSucceeded: false,
    launchAttempted: false, launchSucceeded: false, postVerified: false, captureStatus: 'not-attempted'};
  try {
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
    const phone = await wiredPhone(profileDevices);
    const identifier = phone.identifier;
    await checkUnlocked(identifier);
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
    await wiredPhone(profileDevices, identifier);
    await checkUnlocked(identifier);
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
    const after = await wiredPhone(profileDevices, identifier);
    requireProof(after.deviceProperties?.ddiServicesAvailable === true, 'Developer disk image services were not verified after launch.');
    requireProof(await recheckArtifact() === true, 'The candidate no longer matches the verified artifact.');
    receipt.postVerified = true;
    receipt.stage = 'complete';
  } catch (error) {
    receipt.blocker = error instanceof PhoneBlocker ? error.message : 'Delivery could not verify the current stage.';
  }
  return receipt;
}
