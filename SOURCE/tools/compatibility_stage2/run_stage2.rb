# frozen_string_literal: true

# Candidate-only runner. No network acquisition, project configuration, app
# integration, credentials or production connection is implemented here.
require 'json'
require 'digest'
require 'open3'
require 'fileutils'
require 'timeout'
require 'time'
require 'yaml'

class Stage2Runner
  ROOT = File.realpath(__dir__)
  SOURCE = File.realpath(File.join(ROOT, '../..'))
  ZYRA = File.dirname(SOURCE)
  REVIEW = File.join(ZYRA, 'SYSTEM/RESOURCES/REVIEWS')
  RUNTIME = File.join(REVIEW, 'COMPATIBILITY_UNLOCK_STAGE2_RUNTIME_2026-09-28')
  OWNERSHIP = 'zyra.compatibility.stage2=2026-09-28-synthetic'
  DB = 'zyra_compat_stage2_research'
  CONTAINER = 'zyra-compat-stage2-db'
  VOLUME = 'zyra-compat-stage2-data'
  SOCKET = '/Users/shakeelahmad/.colima/zyra-compat-stage2/docker.sock'
  SQL_FILES = %w[00_local_roles.sql 10_synthetic_dependencies.sql
                 20_semantic_inputs.sql 30_snapshot_entitlement_state.sql
                 40_private_calculator.sql 50_purpose_interfaces.sql
                 60_transaction_lifecycle.sql 70_maintenance_repair.sql].freeze

  def initialize
    @manifest = JSON.parse(File.read(File.join(ROOT, 'sandbox_manifest.json')))
    raise 'Manifest target drift' unless @manifest.values_at('socket', 'container', 'volume', 'database', 'ownership_label') == [SOCKET, CONTAINER, VOLUME, DB, OWNERSHIP]
    raise 'Production authority is forbidden' unless @manifest['production_authority'] == false
    @commands = []
    @mutex = Mutex.new
  end

  def clean_env
    # Docker reads only this task's empty configuration directory, never the
    # user's credential helpers. No project environment is loaded.
    { 'PATH' => '/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin',
      'LANG' => 'en_US.UTF-8', 'LC_ALL' => 'en_US.UTF-8' }
  end

  def command(argv, stdin: '', timeout: 45)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    stdout = stderr = ''
    exit_status = nil
    timed_out = false
    Open3.popen3(clean_env, *argv, unsetenv_others: true, pgroup: true) do |input, output, errors, waiter|
      readers = [Thread.new { output.read }, Thread.new { errors.read }]
      begin
        Timeout.timeout(timeout) do
          input.write(stdin)
          input.close
          exit_status = waiter.value.exitstatus
        end
      rescue Timeout::Error
        timed_out = true
        Process.kill('TERM', -waiter.pid) rescue Errno::ESRCH
        unless waiter.join(2)
          Process.kill('KILL', -waiter.pid) rescue Errno::ESRCH
          waiter.join
        end
        exit_status = 124
      ensure
        input.close unless input.closed?
        stdout, stderr = readers.map(&:value)
      end
    end
    result = { stdout: stdout, stderr: stderr, status: exit_status, timed_out: timed_out }
    @mutex.synchronize do
      @commands << { argv: argv, status: exit_status, timed_out: timed_out, stdout: stdout,
                     stderr: stderr, elapsed_seconds: Process.clock_gettime(Process::CLOCK_MONOTONIC) - start,
                     stdin_sha256: Digest::SHA256.hexdigest(stdin) }
    end
    result
  end

  def docker(*args, stdin: '')
    raise 'Dedicated Docker socket absent: do not start another context' unless File.socket?(SOCKET)
    config = File.join(RUNTIME, 'empty-docker-config')
    FileUtils.mkdir_p(config)
    config_file = File.join(config, 'config.json')
    if File.exist?(config_file)
      raise 'Docker config symlink forbidden' if File.symlink?(config_file)
      parsed = JSON.parse(File.read(config_file))
      raise 'Credentials forbidden in task Docker config' unless (parsed['auths'] || {}).empty? &&
        (parsed['credHelpers'] || {}).empty? && parsed['credsStore'].nil?
    end
    command(['/opt/homebrew/bin/docker', '--config', config, '--host', "unix://#{SOCKET}", *args], stdin: stdin)
  end

  def must(result, label)
    raise "#{label}: #{result[:stderr]}" unless result[:status] == 0
    result[:stdout]
  end

  def psql(sql, user: 'postgres')
    raise 'Unexpected synthetic session identity' unless @manifest.fetch('fixture_roles').include?(user)
    docker('exec', '-i', CONTAINER, 'psql', '-X', '-q', '-A', '-t',
           '-v', 'ON_ERROR_STOP=1', '-U', user, '-d', DB, stdin: sql)
  end

  def baseline
    previous = JSON.parse(File.read(File.join(REVIEW, 'COMPATIBILITY_UNLOCK_STAGE1_EXECUTION_EVIDENCE_2026-09-28.json')))
    rows = previous.fetch('source_hash_checks').fetch('baseline') +
           previous.fetch('additional_unchanged_baselines') +
           previous.fetch('source_hash_checks').fetch('new_files')
    checked = rows.map do |row|
      relative = row.fetch('path')
      raise 'Unsafe baseline path' unless relative.start_with?('SOURCE/') && !relative.include?('..')
      path = File.join(ZYRA, relative)
      expected = row['expected'] || row.fetch('sha256')
      actual = Digest::SHA256.file(path).hexdigest
      { path: relative, expected: expected, actual: actual, matched: actual == expected }
    end
    raise 'Stage 1/runtime source baseline drift' unless checked.all? { |r| r[:matched] }
    checked
  end

  def candidate_hashes
    Dir.glob(File.join(ROOT, '**/*')).select { |p| File.file?(p) }.sort.map do |path|
      raise 'Symlink in candidate files' if File.symlink?(path)
      { path: path, sha256: Digest::SHA256.file(path).hexdigest }
    end
  end

  def candidate_file(relative)
    raise 'Unsafe candidate path' if relative.start_with?('/') || relative.split('/').include?('..')
    path = File.join(ROOT, relative)
    raise 'Candidate symlink/path escape' unless File.realpath(path) == path
    File.read(path)
  end

  def inspect_runtime(marker: true)
    raw = must(docker('inspect', CONTAINER), 'container inspect')
    item = JSON.parse(raw).fetch(0)
    raise 'Wrong container ownership' unless item.dig('Config', 'Labels', 'zyra.compatibility.stage2') == '2026-09-28-synthetic'
    raise 'Container network drift' unless item.dig('HostConfig', 'NetworkMode') == 'none'
    raise 'Published ports forbidden' unless (item.dig('HostConfig', 'PortBindings') || {}).empty?
    mounts = item.fetch('Mounts', [])
    raise 'Host/secret mount forbidden' unless mounts.size == 1 && mounts.all? { |m| m['Type'] == 'volume' && m['Name'] == VOLUME && m['Destination'] == '/var/lib/postgresql/data' }
    raise 'Docker socket/privilege forbidden' if item.dig('HostConfig', 'Privileged')
    raise 'Exact image digest not pinned' unless @manifest['image'].to_s.match?(/\Apostgres@sha256:[0-9a-f]{64}\z/)
    raise 'Container image drift' unless item.dig('Config', 'Image') == @manifest['image']
    runtime = JSON.parse(must(psql("SELECT json_build_object('database',current_database(),'version',current_setting('server_version'),'listen',current_setting('listen_addresses'),'isolation',current_setting('default_transaction_isolation'));"), 'server identity'))
    raise 'Database identity/listening drift' unless runtime['database'] == DB && runtime['listen'] == '' && runtime['version'].split(' ').first == @manifest.fetch('postgres_version')
    raise 'Default isolation drift' unless runtime['isolation'] == 'serializable'
    if marker
      identity = must(psql('SELECT marker FROM s2_private.sandbox_identity;'), 'database marker').strip
      raise 'Wrong sandbox marker' unless identity == 'compatibility-stage2-synthetic-only'
    end
    { container: item['Id'], image: item['Image'], config_image: item.dig('Config', 'Image'),
      network: 'none', port_bindings: {}, mounts: item.fetch('Mounts'), server: runtime }
  end

  def inspect_vm
    # Generated VM defaults proved insufficient on this installed version.
    # Refuse setup/testing unless the exact owned instance has the reviewed
    # all-interface ignore rule, no host mounts, and no wildcard listener.
    instance = '/Users/shakeelahmad/.colima/_lima/colima-zyra-compat-stage2'
    path = File.join(instance, 'lima.yaml')
    raise 'VM configuration symlink forbidden' if File.symlink?(path)
    config = YAML.safe_load(File.read(path), permitted_classes: [], aliases: false)
    raise 'VM host mounts enabled' unless (config['mounts'] || []).empty?
    raise 'VM SSH agent enabled' if config.dig('ssh', 'forwardAgent') == true
    forwards = config.fetch('portForwards')
    safe = forwards.any? { |rule| rule['ignore'] == true && rule['guestIP'] == '0.0.0.0' &&
      rule['guestIPMustBeZero'] == false && rule['proto'] == 'any' && rule['guestPortRange'] == [1, 65535] }
    raise 'All-interface VM port ignore missing' unless safe
    raise 'VM network forwarding rule present' if forwards.any? { |rule| rule['guestSocket'].nil? && rule['ignore'] != true }
    pid = File.read(File.join(instance, 'ha.pid')).strip
    raise 'Invalid VM hostagent PID' unless pid.match?(/\A[1-9][0-9]*\z/)
    process = must(command(['/bin/ps', '-p', pid, '-o', 'command=']), 'owned VM process')
    raise 'VM process ownership mismatch' unless process.include?('limactl hostagent') && process.include?(instance)
    sockets = command(['/usr/sbin/lsof', '-nP', '-a', '-p', pid, '-i'])
    raise 'VM socket inspection failed' unless [0, 1].include?(sockets[:status]) && sockets[:stderr].empty?
    raise 'Wildcard VM network listener' if sockets[:stdout].lines.any? { |line| line.include?('*:') && (line.include?('(LISTEN)') || line.include?('UDP')) }
    { config_sha256: Digest::SHA256.file(path).hexdigest, hostagent_pid: pid,
      hostagent_network_sockets: sockets[:stdout], all_interface_ignore: true,
      mounts: [], ssh_agent: false }
  end

  def export
    result = command(['/opt/homebrew/bin/dart', "--packages=#{File.join(SOURCE, '.dart_tool/package_config.json')}", File.join(ROOT, 'export_stage1.dart')], timeout: 45)
    JSON.parse(must(result, 'Stage1 export'))
  end

  def setup
    baseline
    candidate_hashes
    inspect_vm
    raise 'Pinned image required before runtime setup' unless @manifest['image'].to_s.match?(/\Apostgres@sha256:[0-9a-f]{64}\z/)
    raise 'Existing named container: never overwrite' if docker('container', 'inspect', CONTAINER)[:status] == 0
    raise 'Existing named volume: never overwrite' if docker('volume', 'inspect', VOLUME)[:status] == 0
    must(docker('image', 'inspect', @manifest['image']), 'cached pinned image (no automatic pull)')
    must(docker('volume', 'create', '--label', OWNERSHIP, VOLUME), 'owned volume create')
    must(docker('run', '-d', '--pull', 'never', '--network', 'none', '--name', CONTAINER,
                '--label', OWNERSHIP, '--restart', 'no', '--memory', '1g', '--pids-limit', '128',
                '--security-opt', 'no-new-privileges', '--mount', "type=volume,src=#{VOLUME},dst=/var/lib/postgresql/data",
                '-e', "POSTGRES_DB=#{DB}", '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
                '-e', 'POSTGRES_INITDB_ARGS=--auth-local=trust --auth-host=reject',
                @manifest['image'], 'postgres', '-c', 'listen_addresses=',
                '-c', 'default_transaction_isolation=serializable', '-c', 'statement_timeout=15000',
                '-c', 'lock_timeout=10000', '-c', 'idle_in_transaction_session_timeout=20000'), 'container create')
    ready = false
    30.times do
      result = psql('SELECT 1;')
      if result[:status] == 0
        ready = true
        break
      end
      sleep 0.5
    end
    raise 'Local PostgreSQL did not initialise' unless ready
    inspect_runtime(marker: false)
    SQL_FILES.each do |name|
      must(psql(candidate_file("sql/#{name}")), "candidate SQL #{name}")
    end
    must(psql(candidate_file('fixtures/test_setup.sql')), 'privileged synthetic fixtures')
    must(psql(candidate_file('tests/assertions.sql')), 'privileged assertions')
    data = export
    text = JSON.generate(data).gsub("'", "''")
    must(psql("SELECT s2_fixture.seed('#{text}'::jsonb);"), 'full synthetic manifest/input seed')
    smoke = JSON.parse(must(psql("SELECT jsonb_build_array(s2_private.calculate('synthetic-viewer','synthetic-target')->>'state',s2_private.calculate('synthetic-target','synthetic-viewer')->>'state');"), 'both-direction calculator runtime smoke'))
    raise 'Calculator runtime smoke must succeed in both directions' unless smoke == %w[success success]
    inspect_runtime
  end

  def test
    before = baseline
    hashes_before = candidate_hashes
    vm = inspect_vm
    runtime = inspect_runtime
    data = export
    require File.join(ROOT, 'tests/harness')
    results = Stage2Tests.run(method(:psql), export: data)
    after = baseline
    raise 'Candidate source changed during tests' unless hashes_before == candidate_hashes
    local_isolation = {
      'ISO01' => {connection: "unix://#{SOCKET}", database: DB,
        scope: 'this run only; clean child environment; synthetic source export; no remote DB path'},
      'ISO02' => {network: runtime[:network], port_bindings: runtime[:port_bindings],
        postgres_listen: runtime[:server]['listen'], vm: vm},
      'ISO03' => {config_image: runtime[:config_image], image: runtime[:image],
        database: runtime[:server]['database'], version: runtime[:server]['version'], ownership: OWNERSHIP},
      'ISO04' => {child_environment_keys: clean_env.keys.sort, container_mounts: runtime[:mounts],
        vm_mounts: vm[:mounts], vm_ssh_agent: vm[:ssh_agent]},
      'ISO05' => {protected_source_hashes: before.size, mismatches: 0, checked_before_and_after: true}
    }
    raise 'Unexpected child environment' unless clean_env.keys.sort == %w[LANG LC_ALL PATH]
    results = results.map do |row|
      id = row[:id] || row['id']
      if local_isolation.key?(id)
        row.reject { |key, _| %w[status reason detail].include?(key.to_s) }.merge(
          status: 'passed', detail: local_isolation.fetch(id), execution_source: 'root actual runtime inspection')
      else
        row
      end
    end
    evidence = {
      timestamp_utc: Time.now.utc.iso8601, status: results.any? { |r| r[:status] == 'failed' || r['status'] == 'failed' } ? 'failed' : 'local tests measured; inspect pending gates',
      authority: @manifest.fetch('authority'), production_authority: false,
      environment: runtime, vm_isolation: vm, manifest: @manifest, candidate_hashes: hashes_before,
      baselines_before: before, baselines_after: after, results: results, commands: @commands,
      scope: 'synthetic local PostgreSQL only; no Flutter wiring, real data, remote connection or spending',
      limitations: ['No production JWT/gateway or live ACL proof', 'No approved disclosure thresholds or retention periods',
                    'Synthetic observable-transcript findings are not privacy-risk acceptance', 'Founder acceptance pending']
    }
    FileUtils.mkdir_p(REVIEW)
    stamp = Time.now.utc.strftime('%Y%m%dT%H%M%SZ')
    path = File.join(REVIEW, "COMPATIBILITY_UNLOCK_STAGE2_RUN_#{stamp}.json")
    raise 'Evidence collision' if File.exist?(path)
    File.write(path, JSON.pretty_generate(evidence) + "\n")
    puts JSON.pretty_generate({ evidence: path, outcomes: results.group_by { |r| r[:status] || r['status'] }.transform_values(&:size) })
    exit 1 if evidence[:status] == 'failed'
  end

  def teardown
    # A failed initial schema load must still be recoverably removable after
    # exact ownership, image, database and network checks. No SQL marker is
    # assumed to have been created during a failed setup.
    inspect_runtime(marker: false)
    volume = JSON.parse(must(docker('volume', 'inspect', VOLUME), 'volume ownership')).first
    raise 'Volume ownership drift' unless volume.dig('Labels', 'zyra.compatibility.stage2') == '2026-09-28-synthetic'
    must(docker('stop', '--time', '10', CONTAINER), 'stop exact owned sandbox')
    must(docker('rm', CONTAINER), 'remove exact disposable synthetic container')
    must(docker('volume', 'rm', VOLUME), 'remove exact disposable synthetic volume')
    puts JSON.generate({ removed: [CONTAINER, VOLUME], synthetic_data_only: true, profile_removal: 'root verifies exact created profile separately', recoverability: 'only retained synthetic evidence survives' })
  end

  def run(mode)
    started = Time.now.utc.iso8601
    case mode
    when 'baseline' then puts JSON.pretty_generate({ checked: baseline.size, mismatches: [] })
    when 'inspect' then puts JSON.pretty_generate(inspect_runtime)
    when 'setup' then puts JSON.pretty_generate(setup)
    when 'test' then test
    when 'teardown' then teardown
    else raise 'Use baseline, inspect, setup, test or teardown; runtime acquisition is never automatic'
    end
  rescue StandardError => error
    journal(mode, started, error)
    raise
  ensure
    journal(mode, started) if %w[setup inspect teardown].include?(mode) && !$!
  end

  def journal(mode, started, error = nil)
    FileUtils.mkdir_p(REVIEW)
    stamp = Time.now.utc.strftime('%Y%m%dT%H%M%S%6NZ')
    path = File.join(REVIEW, "COMPATIBILITY_UNLOCK_STAGE2_COMMANDS_#{mode}_#{stamp}.json")
    raise 'Evidence collision' if File.exist?(path)
    File.write(path, JSON.pretty_generate({ mode: mode, started_utc: started,
      finished_utc: Time.now.utc.iso8601, status: error ? 'failed' : 'completed',
      error: error && { type: error.class.name, message: error.message },
      production_authority: false, commands: @commands }) + "\n")
    warn "Command evidence: #{path}"
  end
end

Stage2Runner.new.run(ARGV.fetch(0, 'baseline')) if $PROGRAM_NAME == __FILE__
