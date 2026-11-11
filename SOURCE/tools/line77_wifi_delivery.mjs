import {createHash} from 'node:crypto';
import fs from 'node:fs';
import {registerHooks} from 'node:module';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';

const source = path.resolve(fileURLToPath(new URL('..', import.meta.url)));
const repo = path.dirname(source);
const packetName = 'ZYRA_LINE77_2026_11_11_A';
const packet = path.join(repo, 'REPORTS/EVIDENCE', packetName);
const root = path.join(source, 'build/review-work', packetName, 'HOST_PROFILE');
const planPath = path.join(packet, 'HOST_PROFILE_PLAN.json');
const receiptPath = path.join(root, 'BUILD.json');
const hostPath = path.join(source, 'tooling/verified_host_profile.mjs');
const phonePath = path.join(source, 'tooling/verified_phone_delivery.mjs');
const hostUrl = pathToFileURL(hostPath).href;
const phoneUrl = pathToFileURL(phonePath).href;
const commit = '6a5623d3ece525fe7308646c7aa63fa4d3af87e3';
const planSha = '646545d5a2fa080c6af77bd08bf5aea3184047ffee957dc42678fe4698feda2c';
const sealSha = '8e09abae9e19be4016e6095cf3d0f2987d08dfdf01829e04a2f80a97c6b08ff1';
const receiptSha = '9a09b8f3f82aec2d31eac63bf92a4a5d25fde712ececda7e9631a5beb4e0ed9c';
const hostSha = 'f4ee804ba4173b47589ca40490e91335faf16029d133e0c1bee95a55aeea7957';
const phoneSha = '779db4b10d20b96e9c63db680270c3b6f214bc7244a343658d4f5950d31f1e1e';
const wifiPhoneSha = 'e77eee2294a0a2a7d1ce41f20fd7a366dd6c1bb547b211f1886705375ca7e3de';
const sha = bytes => createHash('sha256').update(bytes).digest('hex');

function requireExact(proven, reason) {
  if (!proven) throw Error(reason);
}

function checkedBytes(file, expected) {
  requireExact(fs.lstatSync(file).isFile() && fs.realpathSync(file) === file, 'Expected a canonical regular file.');
  const bytes = fs.readFileSync(file);
  requireExact(expected === undefined || sha(bytes) === expected, 'Pinned file digest differs.');
  return bytes;
}

function exactReplacement(sourceCode, original, replacement) {
  const index = sourceCode.indexOf(original);
  requireExact(index >= 0 && sourceCode.indexOf(original, index + original.length) < 0,
    'Expected exactly one protected transport fragment.');
  return sourceCode.slice(0, index) + replacement + sourceCode.slice(index + original.length);
}

export function wirelessHelper(original) {
  let code = original.toString('utf8');
  code = exactReplacement(code, "transportType === 'wired'", "transportType === 'localNetwork'");
  code = exactReplacement(code, 'Connect the single paired, provisioned iPhone by USB and keep it unlocked.',
    'Connect the single paired, provisioned iPhone over Wi-Fi and keep it unlocked.');
  code = exactReplacement(code, 'async function wiredPhone(profileDevices, expectedIdentifier) {',
    'let selectedWifiPhone;\n\nasync function wiredPhone(profileDevices, expectedIdentifier) {');
  code = exactReplacement(code, "    'The wired iPhone changed during delivery.');\n  return wired[0];",
    "    'The Wi-Fi iPhone changed during delivery.');\n" +
    "  requireProof(selectedWifiPhone === undefined || selectedWifiPhone === wired[0].identifier,\n" +
    "    'The Wi-Fi iPhone changed during delivery.');\n" +
    "  selectedWifiPhone = wired[0].identifier;\n  return wired[0];");
  code = exactReplacement(code, 'The wired iPhone did not report its current lock state.',
    'The Wi-Fi iPhone did not report its current lock state.');
  code = exactReplacement(code, 'Unlock the wired iPhone and keep its screen awake.',
    'Unlock the Wi-Fi iPhone and keep its screen awake.');
  code = exactReplacement(code, 'paired: true, wired: true, unlocked: true',
    "paired: true, transport: 'localNetwork', unlocked: true");
  requireExact(code.split('wiredPhone(').length === 6, 'Unexpected phone selection call count.');
  code = code.replaceAll('wiredPhone(', 'wifiPhone(');
  return Buffer.from(code);
}

function checkArtifactInputs() {
  const plan = JSON.parse(checkedBytes(planPath, planSha));
  const seal = JSON.parse(checkedBytes(path.join(packet, 'CHECKED_PREBUILD.json'), sealSha));
  const receipt = JSON.parse(checkedBytes(receiptPath, receiptSha));
  const published = JSON.parse(checkedBytes(path.join(packet, 'BUILD.json')));
  requireExact(plan.schema === 3 && plan.source === source && plan.sourceCommit === commit &&
    plan.sourceSeal === 'CHECKED_PREBUILD.json' && seal.source === source && seal.sourceCommit === commit &&
    seal.files['tooling/verified_host_profile.mjs'] === hostSha && seal.files['tooling/verified_phone_delivery.mjs'] === phoneSha &&
    receipt.schema === 2 && receipt.success === true && receipt.commitSha === commit && receipt.root === root &&
    receipt.candidate === path.join(root, 'Runner.app') && receipt.planSha256 === planSha && receipt.sourceSealSha256 === sealSha &&
    published.success === true && published.commitSha === commit && published.buildMode === 'profile' &&
    published.buildReceipt === receiptPath && published.buildReceiptSha256 === receiptSha,
  'The protected plan, source seal and build receipt disagree.');
  checkedBytes(hostPath, hostSha);
  const helper = wirelessHelper(checkedBytes(phonePath, phoneSha));
  requireExact(sha(helper) === wifiPhoneSha, 'Wireless helper digest differs.');
  return helper;
}

async function main() {
  const [mode, ...extra] = process.argv.slice(2);
  requireExact(extra.length === 0 && ['verify', 'phone-check', 'deliver'].includes(mode) &&
    process.execArgv.length === 0 && !process.env.NODE_OPTIONS && !process.env.NODE_PATH,
  'Use verify, phone-check, or deliver with no additional Node options or arguments.');
  const wifiHelper = checkArtifactInputs();
  if (mode === 'verify') {
    console.log(JSON.stringify({verified: true, wifiTransport: 'localNetwork', buildReceiptSha256: receiptSha,
      wirelessHelperSha256: sha(wifiHelper)}));
    return;
  }

  let loadedWifiHelper = false;
  const hooks = registerHooks({load(url, context, nextLoad) {
    const loaded = nextLoad(url, context);
    if (url === hostUrl) {
      requireExact(loaded.format === 'module' && sha(loaded.source) === hostSha, 'Loaded protected host differs.');
    } else if (url === phoneUrl) {
      requireExact(!loadedWifiHelper && loaded.format === 'module' && sha(loaded.source) === phoneSha,
        'Loaded protected phone helper differs.');
      loadedWifiHelper = true;
      return {...loaded, source: wifiHelper};
    }
    return loaded;
  }});
  process.argv = [process.execPath, hostPath, mode, planPath];
  if (mode === 'deliver') process.argv.push(receiptSha);
  try {
    await import(hostUrl);
    requireExact(loadedWifiHelper, 'The exact protected helper was not loaded.');
  } finally {
    hooks.deregister();
  }
}

if (process.argv[1] && pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url) {
  main().catch(error => {
    console.error(error instanceof Error ? error.message : 'Protected Wi-Fi delivery stopped.');
    process.exitCode = 1;
  });
}
