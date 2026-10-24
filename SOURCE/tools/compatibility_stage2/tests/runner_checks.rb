# frozen_string_literal: true

# Database-free checks. These must never be represented as SQL, ACL, race,
# privacy or purchase evidence. No image pull or VM startup occurs here.
require_relative '../run_stage2'

module Stage2RunnerChecks
  def self.canonical_json(value)
    case value
    when Hash then '{' + value.keys.sort.map { |key| JSON.generate(key) + ':' + canonical_json(value.fetch(key)) }.join(',') + '}'
    when Array then '[' + value.map { |entry| canonical_json(entry) }.join(',') + ']'
    else JSON.generate(value)
    end
  end

  class InspectFixture < Stage2Runner
    attr_reader :item, :server

    def initialize
      super
      @item = {
        'Id' => 'synthetic-container-inspection', 'Image' => 'synthetic-image-id',
        'Config' => { 'Image' => @manifest.fetch('image'),
                      'Labels' => { 'zyra.compatibility.stage2' => '2026-09-28-synthetic' } },
        'HostConfig' => { 'NetworkMode' => 'none', 'PortBindings' => {}, 'Privileged' => false },
        'Mounts' => [{ 'Type' => 'volume', 'Name' => Stage2Runner::VOLUME,
                       'Destination' => '/var/lib/postgresql/data' }]
      }
      @server = { 'database' => Stage2Runner::DB, 'version' => @manifest.fetch('postgres_version'),
                  'listen' => '', 'isolation' => 'serializable' }
    end

    def docker(*_args, stdin: '')
      { status: 0, stdout: JSON.generate([@item]), stderr: '' }
    end

    def psql(sql, user: 'postgres')
      text = sql.include?('json_build_object') ? JSON.generate(@server) : 'compatibility-stage2-synthetic-only'
      { status: 0, stdout: text, stderr: '' }
    end
  end

  def self.run
    results = []
    verify = lambda do |id, &block|
      detail = block.call
      results << { id: id, status: 'passed', detail: detail }
    rescue StandardError => error
      results << { id: id, status: 'failed', detail: "#{error.class}: #{error.message}" }
    end
    reject = lambda do |fixture, expected|
      begin
        fixture.inspect_runtime
      rescue StandardError => error
        raise "Wrong refusal: #{error.message}" unless error.message.include?(expected)
        next error.message
      end
      raise 'Unsafe runtime inspection unexpectedly accepted'
    end

    runner = Stage2Runner.new
    verify.call('STATIC01') { { protected_hashes: runner.baseline.size, mismatches: 0 } }
    verify.call('STATIC02') do
      raise 'Project environment inherited' unless runner.clean_env.keys.sort == %w[LANG LC_ALL PATH]
      { inherited_environment: runner.clean_env.keys.sort }
    end
    verify.call('STATIC03') do
      output = runner.command(['/usr/bin/ruby', '-e', 'print "synthetic-process-ok"'])
      raise 'Command capture failed' unless output[:status] == 0 && output[:stdout] == 'synthetic-process-ok'
      { subprocess_capture: true }
    end
    verify.call('STATIC04') do
      output = runner.command(['/usr/bin/ruby', '-e', 'STDOUT.sync=true; print "before-timeout"; sleep 5'], timeout: 0.1)
      raise 'Timeout was not bounded/recorded' unless output[:status] == 124 && output[:timed_out] && output[:stdout] == 'before-timeout'
      { controlled_child_timeout: true, synthetic_process_only: true }
    end
    verify.call('STATIC05') { InspectFixture.new.inspect_runtime; { synthetic_inspection_accepted: true } }
    {
      'STATIC06' => ['ownership', ->(f) { f.item['Config']['Labels']['zyra.compatibility.stage2'] = 'unrelated' }],
      'STATIC07' => ['network', ->(f) { f.item['HostConfig']['NetworkMode'] = 'bridge' }],
      'STATIC08' => ['ports', ->(f) { f.item['HostConfig']['PortBindings'] = { '5432/tcp' => [{}] } }],
      'STATIC09' => ['mount', ->(f) { f.item['Mounts'][0]['Type'] = 'bind' }],
      'STATIC10' => ['mount', ->(f) { f.item['Mounts'] = [] }],
      'STATIC11' => ['privilege', ->(f) { f.item['HostConfig']['Privileged'] = true }],
      'STATIC12' => ['image drift', ->(f) { f.item['Config']['Image'] = 'postgres:latest' }],
      'STATIC13' => ['identity', ->(f) { f.server['database'] = 'unrelated-database' }],
      'STATIC14' => ['identity', ->(f) { f.server['listen'] = '*' }],
      'STATIC15' => ['isolation', ->(f) { f.server['isolation'] = 'read committed' }]
    }.each do |id, (reason, mutation)|
      verify.call(id) do
        fixture = InspectFixture.new
        mutation.call(fixture)
        { synthetic_drift_refusal: reject.call(fixture, reason) }
      end
    end
    verify.call('STATIC16') do
      begin
        runner.candidate_file('../README.md')
      rescue StandardError => error
        raise unless error.message.include?('Unsafe candidate path')
        next { traversal_refused: true }
      end
      raise 'Traversal unexpectedly accepted'
    end
    verify.call('STATIC17') do
      files = runner.candidate_hashes
      json = files.select { |file| File.extname(file[:path]) == '.json' }
      json.each { |file| JSON.parse(File.read(file[:path])) }
      inventory = JSON.parse(runner.candidate_file('tests/test_inventory.json')).fetch('tests')
      ids = inventory.map { |test| test.fetch('id') }
      raise 'Duplicate named test IDs' unless ids.uniq.size == ids.size
      { json_files_parsed: json.size, unique_database_inventory_cases: ids.size }
    end
    data = nil
    verify.call('STATIC18') do
      data = runner.export
      manifest = data.fetch('manifest')
      raise 'Unexpected answer bank size' unless manifest.fetch('answers').size == 105
      raise 'Unexpected preference bank size' unless manifest.fetch('preferences').size == 72
      raise 'Unexpected category size' unless manifest.fetch('categories').size == 12
      { answer_definitions: 105, preference_controls: 72, categories: 12,
        export_keys: data.keys, database_parity_not_measured: true }
    end
    verify.call('STATIC19') do
      raise 'Export required' unless data
      hash = Digest::SHA256.hexdigest(canonical_json(data.fetch('manifest')))
      expected = '1fac439a6556922b06ee9810fe8daec076c86cf03a38cc8f961460dd7c02e862'
      raise 'Manifest source pin drift' unless hash == expected && runner.candidate_file('sql/20_semantic_inputs.sql').include?(expected)
      { host_manifest_sha256: hash, postgres_serializer_parity_not_measured: true }
    end
    verify.call('STATIC20') do
      files = ['run_stage2.rb', 'acquire_runtime.rb', 'tests/harness.rb', 'tests/runner_checks.rb']
      files.each do |relative|
        output = runner.command(['/usr/bin/ruby', '-c', File.join(Stage2Runner::ROOT, relative)])
        raise "Ruby syntax failed: #{relative}" unless output[:status] == 0 && output[:stdout].include?('Syntax OK')
      end
      { ruby_syntax_files: files, sql_compilation_not_measured: true }
    end
    verify.call('STATIC21') do
      output = runner.command(['/opt/homebrew/bin/dart', 'analyze', File.join(Stage2Runner::ROOT, 'export_stage1.dart')])
      raise 'Scoped exporter analyzer not clean' unless output[:status] == 0 && output[:stdout].include?('No issues found!')
      { scoped_exporter_analyzer: 'No issues found!', production_analysis_not_claimed: true }
    end
    { scope: 'database-free candidate runner/export checks only',
      database_tests_executed: false, production_authority: false,
      runtime_prerequisite: { dedicated_socket_present: File.socket?(Stage2Runner::SOCKET),
        acquisition_approved: true, database_started_by_this_run: false },
      results: results, commands: runner.instance_variable_get(:@commands) }
  end
end

if $PROGRAM_NAME == __FILE__
  report = Stage2RunnerChecks.run
  report[:timestamp_utc] = Time.now.utc.iso8601
  report[:candidate_hashes] = Stage2Runner.new.candidate_hashes
  report[:protected_baselines] = Stage2Runner.new.baseline
  report[:database_inventory] = JSON.parse(File.read(File.join(__dir__, 'test_inventory.json'))).fetch('tests').map do |test|
    test.merge('status' => 'not_executed_by_static_run', 'reason' => 'Static checks do not run SQL; consult the separately timestamped runtime suite evidence.')
  end
  evidence_path = nil
  if ARGV == ['--evidence']
    FileUtils.mkdir_p(Stage2Runner::REVIEW)
    stamp = Time.now.utc.strftime('%Y%m%dT%H%M%S%6NZ')
    evidence_path = File.join(Stage2Runner::REVIEW, "COMPATIBILITY_UNLOCK_STAGE2_STATIC_#{stamp}.json")
    raise 'Evidence collision' if File.exist?(evidence_path)
    File.write(evidence_path, JSON.pretty_generate(report) + "\n")
  elsif !ARGV.empty?
    raise 'Only --evidence is supported; no database or runtime acquisition mode exists here'
  end
  puts JSON.pretty_generate({ scope: report[:scope], evidence: evidence_path,
    checks: report[:results], pending_database_cases: report[:database_inventory].size })
  exit 1 if report.fetch(:results).any? { |result| result[:status] == 'failed' }
end
