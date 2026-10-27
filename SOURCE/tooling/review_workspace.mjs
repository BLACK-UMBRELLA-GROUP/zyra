// OA-AIOS-400 / OA-AIOS-411: evidence contains text and screenshots, never build workspaces.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

function workspacePath(source, packet, label) {
  if (!path.isAbsolute(source) || path.resolve(source) !== source ||
      path.dirname(packet) !== path.resolve(source, '../REPORTS/EVIDENCE') ||
      !/^[A-Za-z0-9][A-Za-z0-9_.-]+$/.test(path.basename(packet)) ||
      !/^(?:HOST_PROFILE|LOCAL_IOS_PROJECTION(?:_\d+)?)$/.test(label)) {
    throw Error('Unowned review workspace');
  }
  return path.join(source, 'build/review-work', path.basename(packet), label);
}

function plainDirectory(directory, create = false) {
  if (create && !fs.existsSync(directory)) fs.mkdirSync(directory);
  if (!fs.lstatSync(directory).isDirectory() || fs.realpathSync(directory) !== directory) {
    throw Error('Review workspace directory must not be a link');
  }
}

export function assertReviewWorkspace(source, packet, label, root) {
  if (root !== workspacePath(source, packet, label)) throw Error('Review workspace escapes build cache');
  for (const directory of [source, path.join(source, 'build'), path.join(source, 'build/review-work'),
    path.dirname(root), root]) plainDirectory(directory);
  return root;
}

export function createReviewWorkspace(source, packet, label) {
  const root = workspacePath(source, packet, label);
  for (const directory of [source, path.join(source, 'build'), path.join(source, 'build/review-work'),
    path.dirname(root)]) plainDirectory(directory, directory !== source);
  // One immutable build attempt per packet. A repeated evidence export replaces
  // BUILD.json; it does not create timestamped copies of the app or source.
  fs.mkdirSync(root);
  return assertReviewWorkspace(source, packet, label, root);
}

export function readCommitSha(repository) {
  const metadata = path.join(repository, '.git');
  plainDirectory(metadata);
  const head = fs.readFileSync(path.join(metadata, 'HEAD'), 'utf8').trim();
  if (/^[a-f0-9]{40,64}$/.test(head)) return head;
  const reference = head.match(/^ref: (refs\/[A-Za-z0-9_./-]+)$/)?.[1];
  if (!reference || reference.split('/').some(part => !part || part === '.' || part === '..')) {
    throw Error('Cannot identify reviewed commit without running git');
  }
  let commit;
  try {
    commit = fs.readFileSync(path.join(metadata, reference), 'utf8').trim();
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
    const packed = fs.readFileSync(path.join(metadata, 'packed-refs'), 'utf8');
    commit = packed.split('\n').map(line => line.split(' ')).find(parts => parts[1] === reference)?.[0];
  }
  if (!/^[a-f0-9]{40,64}$/.test(commit ?? '')) throw Error('Missing reviewed commit SHA');
  return commit;
}

export function writeBuildEvidence(packet, receipt, {commitSha, flutterVersion, buildMode, target}) {
  if (!/^[a-f0-9]{40,64}$/.test(commitSha ?? '') || !/^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.-]+)?$/.test(flutterVersion ?? '') ||
      !['debug', 'profile', 'release'].includes(buildMode) || typeof target !== 'string' || !target ||
      !Number.isFinite(Date.parse(receipt.started)) || !Number.isFinite(Date.parse(receipt.finished)) ||
      Date.parse(receipt.finished) < Date.parse(receipt.started) || typeof receipt.success !== 'boolean') {
    throw Error('Incomplete text build evidence');
  }
  plainDirectory(packet);
  const file = path.join(packet, 'BUILD.json');
  const record = {schema: 1, commitSha, flutterVersion, buildMode, target,
    buildTimestamp: receipt.started, completedAt: receipt.finished, success: receipt.success,
    buildReceipt: path.join(receipt.root, 'BUILD.json'),
    buildReceiptSha256: crypto.createHash('sha256').update(JSON.stringify(receipt, null, 2) + '\n').digest('hex')};
  // O_NOFOLLOW prevents an existing symlink from redirecting the evidence write.
  const fd = fs.openSync(file, fs.constants.O_WRONLY | fs.constants.O_CREAT | fs.constants.O_TRUNC | fs.constants.O_NOFOLLOW, 0o644);
  try { fs.writeFileSync(fd, JSON.stringify(record, null, 2) + '\n'); }
  finally { fs.closeSync(fd); }
  return record;
}
