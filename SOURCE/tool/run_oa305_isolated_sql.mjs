// New OA305 synthetic replay runner. Never connects to a cloud database.
// Start/stop the existing Colima VM separately under explicit Founder GO.
// Usage: node tool/run_oa305_isolated_sql.mjs f01 fixture.sql assertions.sql
// Or: ... f02|f03 fixture.sql migration.sql assertions.sql
import { readFileSync, realpathSync } from 'node:fs';
import { dirname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync, spawn } from 'node:child_process';
import { createHash, randomUUID } from 'node:crypto';

const source = realpathSync(resolve(dirname(fileURLToPath(import.meta.url)), '..'));
const sqlRoot = realpathSync(resolve(source, 'supabase'));
const socket = 'unix:///Users/shakeelahmad/.colima/zyra-oa198/docker.sock';
const image = 'sha256:28f0e16a019e648089fc1a6d333549a55548f6019c15ae4bd7cd58b989027518';
const pg = '/nix/var/nix/profiles/default/bin';
const [suite, ...arguments_] = process.argv.slice(2);
const refusal = arguments_[0] === '--f01-refusal';
const drift = arguments_[0]?.startsWith('--drift=') ? arguments_[0].slice(8) : null;
const paths = refusal || drift ? arguments_.slice(1) : arguments_;
const configurations = {
  f01: ['zyra_oa305_f01_synthetic', "SET zyra.oa305_f01_local_replay = 'enabled';"],
  f02: ['zyra_oa305_f02_synthetic', "SET zyra.oa305_f02_local_replay = 'enabled';"],
  f03: ['zyra_f03_synthetic_oa305', "SET zyra.synthetic_fixture = 'f03_owner_binding';"],
  f04: ['zyra_oa305_f04_synthetic', "SET zyra.oa305_f04_local_replay = 'prepared_local_replay';"],
  f05: ['zyra_oa305_f05_synthetic', "SET zyra.oa305_f05_local_replay = 'enabled';"],
  f06: ['zyra_f06_f07_synthetic_oa305', "SET zyra.synthetic_fixture = 'f06_f07_unlocks';"],
};
if (!configurations[suite] || paths.length < 2 || paths.length > 3) {
  throw new Error('Expected f01|f02|f03|f04|f05|f06 and two or three synthetic SQL files');
}
if (refusal && suite !== 'f01' || drift &&
    (suite !== 'f02' || !['view','policy','grant','helper','trigger',
      'column_grant','private_column_grant','constraint','index'].includes(drift))) {
  throw new Error('Unknown refusal/drift test');
}
const [database, arm] = configurations[suite];
const inputs = [];
function expand(path, ancestors = []) {
  const full = realpathSync(path);
  if (!full.startsWith(sqlRoot + sep) || !full.endsWith('.sql') || ancestors.includes(full)) {
    throw new Error('SQL include escaped the source tree or was recursive');
  }
  const content = readFileSync(full, 'utf8');
  inputs.push({ path: full, sha256: createHash('sha256').update(content).digest('hex') });
  return content.replace(/^\\ir\s+([^\r\n]+)$/gm, (_, relative) =>
    expand(resolve(dirname(full), relative.trim()), [...ancestors, full]));
}
const expanded = paths.map(p => expand(resolve(source, p)));
const refusalFiles = refusal ? [
  'tests/zyra_oa305_f01_refusal_precheck.sql',
  'migrations/20261005113808_oa305_f01_safety_report_retention.sql',
  'tests/zyra_oa305_f01_refusal_postcheck.sql',
].map(p => expand(resolve(sqlRoot, p))) : [];
const raceFiles = suite === 'f06' ? [
  'f06_f07_different_worker_a.sql', 'f06_f07_different_worker_b.sql',
  'f06_f07_same_worker_a.sql', 'f06_f07_same_worker_b.sql',
  'f06_f07_rr_stale_worker.sql', 'f06_f07_rr_writer.sql',
  'f06_f07_concurrency_assertions.sql',
  'f06_f07_lock_wait_assertions.sql',
].map(name => ({ name, sql: expand(resolve(sqlRoot, 'tests', name)) })) : [];
const sql = arm + '\n' + expanded.join('\n') +
  `\nSELECT 'OA305_${suite.toUpperCase()}_REPLAY_COMPLETE';\n`;
// No shell, exec, COPY PROGRAM, connection changes or arbitrary psql includes.
if ([sql, ...refusalFiles, ...raceFiles.map(f => f.sql)].some(s =>
  /^\s*\\(?:!|i\b|ir\b|connect\b|c\b|o\b|gexec\b)|\bCOPY\s+.*\bPROGRAM\b/im.test(s))) {
  throw new Error('Unsafe synthetic SQL metacommand');
}
function docker(args, input, expectedFailure) {
  const result = spawnSync('/opt/homebrew/bin/docker', ['--host', socket, ...args], {
    input, encoding: 'utf8', timeout: 60000, maxBuffer: 16 * 1024 * 1024,
    env: { PATH: '/opt/homebrew/bin:/usr/bin:/bin' },
  });
  if (result.stdout) process.stdout.write(result.stdout);
  if (result.stderr) process.stderr.write(result.stderr);
  if (expectedFailure) {
    if (result.error || result.status === 0 || !result.stderr.includes(expectedFailure)) {
      throw result.error ?? new Error('Expected exact drift/refusal was not observed');
    }
  } else if (result.error || result.status !== 0) {
    throw result.error ?? new Error(`docker exit ${result.status}`);
  }
  return result.stdout.trim();
}
const name = `zyra-oa305-${suite}-${randomUUID().slice(0, 8)}`;
const label = 'zyra.oa305.synthetic=2026-10-05';
const invocationStart = Date.now();
const pendingWorkers = [];
let id;
try {
  console.log(JSON.stringify({ suite, database, image, inputs, liveDatabase: false }));
  id = docker(['run', '--detach', '--rm', '--pull', 'never', '--name', name,
    '--label', label, '--network', 'none', '--read-only', '--cap-drop', 'ALL',
    '--security-opt', 'no-new-privileges', '--user', '100:101', '--pids-limit', '128',
    '--memory', '768m', '--cpus', '1', '--no-healthcheck',
    '--tmpfs', '/tmp:rw,nosuid,nodev,size=536870912,uid=100,gid=101,mode=0700',
    '--entrypoint', '/bin/sh', image, '-c', 'exec sleep 3600']);
  const inspect = JSON.parse(docker(['inspect', id]))[0];
  if (inspect.Name !== '/' + name || inspect.Image !== image ||
      inspect.Config.Labels?.['zyra.oa305.synthetic'] !== '2026-10-05' ||
      inspect.HostConfig.NetworkMode !== 'none' || !inspect.HostConfig.ReadonlyRootfs ||
      inspect.HostConfig.Binds?.length || inspect.Mounts.some(m => m.Type !== 'tmpfs') ||
      Object.keys(inspect.HostConfig.PortBindings ?? {}).length) {
    throw new Error('Container isolation attestation failed');
  }
  docker(['exec', id, '/bin/sh', '-eu', '-c',
    `test "$(${pg}/postgres --version)" = 'postgres (PostgreSQL) 17.6'; ` +
    `${pg}/initdb -D /tmp/oa305-pg/data --auth-local=trust --auth-host=reject --no-locale --encoding=UTF8; ` +
    `${pg}/pg_ctl -D /tmp/oa305-pg/data -l /tmp/oa305-pg/postgres.log ` +
    `-o "-k /tmp -c listen_addresses='' -c log_statement=none -c log_min_error_statement=panic" -w -t 30 start; ` +
    `${pg}/createdb -h /tmp -U postgres ${database}`]);
  const psql = ['exec', '-i', id, `${pg}/psql`, '-X', '--no-password', '-h', '/tmp',
    '-U', 'postgres', '-d', database, '--set=ON_ERROR_STOP=1'];
  if (drift) {
    if (expanded.length !== 3) throw new Error('Drift expects fixture, drift setup, exact candidate');
    docker(psql, arm + `\n\\set f02_drift_kind ${drift}\n` + expanded.slice(0, 2).join('\n'));
    const fingerprint = `SELECT md5(jsonb_build_object(
      'views',(SELECT jsonb_agg(jsonb_build_object('name',c.relname,'acl',c.relacl::text,'def',pg_get_viewdef(c.oid)) ORDER BY c.relname) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relkind='v'),
      'policies',(SELECT jsonb_agg(to_jsonb(p) ORDER BY schemaname,tablename,policyname) FROM pg_policies p WHERE schemaname IN ('public','private')),
      'functions',(SELECT jsonb_agg(jsonb_build_object('signature',p.oid::regprocedure::text,'acl',p.proacl::text,'def',pg_get_functiondef(p.oid)) ORDER BY p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','private') AND p.prokind='f')
    )::text);`;
    const before = docker([...psql, '-A', '-t'], fingerprint);
    docker(psql, arm + '\n' + expanded[2], 'F02 preflight:');
    const after = docker([...psql, '-A', '-t'], fingerprint);
    if (before !== after) throw new Error('Failed candidate changed persistent catalog');
    console.log(`OA305_F02_DRIFT_${drift.toUpperCase()}_REFUSED_UNCHANGED`);
  } else {
    docker(psql, sql);
  }
  if (suite === 'f06') {
    function worker(file, expectedStatus = 0, requiredError = null, signal = null) {
      let readyResolve, readyReject;
      const ready = new Promise((resolveReady, rejectReady) => {
        readyResolve = resolveReady; readyReject = rejectReady;
      });
      ready.catch(() => {}); // Its caller still observes barrier errors.
      let seen = !signal;
      if (seen) readyResolve();
      const child = spawn('/opt/homebrew/bin/docker', ['--host', socket, ...psql], {
        env: { PATH: '/opt/homebrew/bin:/usr/bin:/bin' },
        stdio: ['pipe', 'pipe', 'pipe'],
      });
      let stdout = '', stderr = '', timedOut = false;
      let killTimer;
      const timer = setTimeout(() => {
        timedOut = true; child.kill('SIGTERM');
        killTimer = setTimeout(() => child.kill('SIGKILL'), 1000);
      }, 45000);
      const completed = new Promise((resolveWorker, rejectWorker) => {
        child.stdout.on('data', chunk => { stdout += chunk; });
        child.stderr.on('data', chunk => {
          stderr += chunk;
          if (!seen && stderr.includes(signal)) { seen = true; readyResolve(); }
        });
        child.on('error', error => {
          clearTimeout(timer); clearTimeout(killTimer); readyReject(error); rejectWorker(error);
        });
        child.on('close', status => {
          clearTimeout(timer); clearTimeout(killTimer);
          console.log(`OA305_RACE_WORKER ${file.name} exit=${status}`);
          process.stdout.write(stdout); process.stderr.write(stderr);
          if (!seen) readyReject(new Error('Worker ended before required barrier'));
          if (timedOut || status !== expectedStatus || requiredError && !stderr.includes(requiredError)) {
            rejectWorker(new Error(`Unexpected race result: ${file.name}`));
          } else resolveWorker();
        });
        child.stdin.end(arm + '\n' + file.sql);
      });
      completed.catch(() => {});
      pendingWorkers.push(completed);
      return { completed, ready };
    }
    // Independent psql sessions share only this invocation's isolated PG.
    for (const offset of [0, 2]) {
      const kind = offset === 0 ? 'DIFFERENT' : 'SAME';
      const a = worker(raceFiles[offset], 0, null, `F06_RC_${kind}_A_LOCK_HELD`);
      await a.ready;
      const b = worker(raceFiles[offset + 1], 0, null, `F06_RC_${kind}_B_RPC_START`);
      await b.ready;
      docker(psql, arm + '\n' + raceFiles[7].sql);
      const pair = [a, b];
      const results = await Promise.allSettled(pair.map(w => w.completed));
      if (results.some(r => r.status !== 'fulfilled')) throw new Error('READ COMMITTED race failed');
    }
    const stale = worker(raceFiles[4], 3, '40001', 'F06_RR_SNAPSHOT_PINNED');
    // Install a rejection handler immediately, before waiting for its barrier.
    const staleResult = stale.completed.then(() => null, error => error);
    await stale.ready;
    const writer = worker(raceFiles[5]);
    const results = await Promise.allSettled([staleResult, writer.completed]);
    if (results.some(r => r.status !== 'fulfilled') || results[0].value) {
      throw new Error('Controlled REPEATABLE READ race failed');
    }
    docker(psql, arm + '\n' + raceFiles[6].sql);
    console.log('OA305_F06_F07_TRUE_CONCURRENT_REPLAY_COMPLETE');
  }
  if (refusal) {
    docker(psql, arm + '\n' + refusalFiles[0]);
    docker(psql, arm + '\n' + refusalFiles[1],
      'F01 precondition: account/reference columns drifted');
    docker(psql, arm + '\n' + refusalFiles[2]);
  }
  console.log(`OA305_${suite.toUpperCase()}_SYNTHETIC_PASS`);
} finally {
  await Promise.allSettled(pendingWorkers);
  if (!id) {
    // A timed-out launch has an unknown outcome. Resolve only this invocation's
    // exact random name; never enumerate or stop unrelated containers.
    const recovery = spawnSync('/opt/homebrew/bin/docker', ['--host', socket, 'inspect', name], {
      encoding: 'utf8', timeout: 15000, env: { PATH: '/opt/homebrew/bin:/usr/bin:/bin' },
    });
    if (!recovery.error && recovery.status === 0) {
      const found = JSON.parse(recovery.stdout)[0];
      if (found.Name === '/' + name && found.Image === image &&
          found.Config.Labels?.['zyra.oa305.synthetic'] === '2026-10-05' &&
          Date.parse(found.Created) >= invocationStart) id = found.Id;
      else throw new Error('Ambiguous launch cleanup refused: ownership mismatch');
    } else if (recovery.error || !recovery.stderr.includes('No such object')) {
      throw new Error('Ambiguous launch could not be resolved; exact-name cleanup required');
    }
  }
  if (id && /^[a-f0-9]{64}$/.test(id)) {
    // The ID was freshly created by this invocation. --rm discards only its
    // synthetic tmpfs database; no user files or existing containers are touched.
    docker(['stop', '--timeout', '10', id]);
    const remaining = docker(['ps', '--all', '--quiet', '--filter', `id=${id}`]);
    if (remaining) throw new Error('Owned synthetic container still present after stop');
    console.log(`OA305_${suite.toUpperCase()}_SYNTHETIC_CONTAINER_STOPPED`);
  }
}
