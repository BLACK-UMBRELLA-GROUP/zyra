# Candidate-only, synthetic PostgreSQL research tests. No connection discovery.
# The root runner owns the exact isolated runtime and supplies every executor.
require 'json'
require 'thread'

module Stage2Tests
  def self.run(executor, export:)
    Suite.new(executor, export).run
  end

  class Suite
    VIEWER = 'synthetic-viewer'
    TARGET = 'synthetic-target'
    TARGET2 = 'synthetic-target2'
    ROLES = %w[s2_anon s2_viewer s2_target s2_other s2_guardian]

    def initialize(executor, export)
      @executor = executor
      @export = export.is_a?(String) ? JSON.parse(export) : export
      @results = []
      @inventory = JSON.parse(File.read(File.join(__dir__, 'test_inventory.json')))['tests']
      @retry_events = []
    end

    def quote(value)
      "'#{value.to_s.gsub("'", "''")}'"
    end

    def execute(sql, user: 'postgres', allow_failure: false)
      answer = @executor.call(sql, user: user)
      answer = answer.transform_keys(&:to_sym)
      unless answer[:status].to_i.zero? || allow_failure
        raise "SQL failed (#{user}): #{answer[:stderr].to_s[-2000, 2000] || answer[:stderr]}"
      end
      answer
    end

    def scalar(sql, user: 'postgres')
      output = execute(sql, user: user)[:stdout].to_s.lines.map(&:strip)
      output.reverse_each do |line|
        next if line.empty? || %w[BEGIN COMMIT SET RESET].include?(line)
        begin
          return JSON.parse(line)
        rescue JSON::ParserError
          next
        end
      end
      raise "No JSON result from SQL: #{output.join(' | ')[0, 400]}"
    end

    def admin(sql)
      attempt = 0
      loop do
        attempt += 1
        answer = execute("\\set VERBOSITY verbose\nBEGIN ISOLATION LEVEL SERIALIZABLE; #{sql}; COMMIT;", allow_failure: true)
        return answer if answer[:status].to_i.zero?
        if answer[:stderr].to_s.match?(/40001|40P01|could not serialize|deadlock detected/) && attempt < 4
          @retry_events << {method: 'admin_fixture', attempt: attempt, error: answer[:stderr].to_s[0, 500]}
          next
        end
        raise "Admin fixture SQL error: #{answer[:stderr]}"
      end
    end

    def reset
      execute('TRUNCATE s2_fixture.injections')
      execute("SELECT s2_fixture.seed(#{quote(JSON.generate(@export))}::jsonb)")
    end

    def check(id)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      reset
      detail = yield
      record(id, 'passed', detail || 'All named assertions observed.', started)
    rescue StandardError => error
      record(id, 'failed', "#{error.class}: #{error.message}", started)
    end

    def record(id, status, detail, started = nil)
      item = @inventory.find { |t| t['id'] == id }
      raise "Unknown test id #{id}" unless item
      @results << {id: id, name: item['name'], status: status, detail: detail,
                   duration_seconds: started ? (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(4) : nil}
    end

    def assert(condition, message)
      raise message unless condition
    end

    def api(method, *arguments, user: 's2_viewer', mutate: true)
      sql = "SELECT s2_api.#{method}(#{arguments.map { |v| quote(v) }.join(',')})"
      return scalar(sql, user: user) unless mutate
      attempt = 0
      loop do
        attempt += 1
        answer = execute("\\set VERBOSITY verbose\nBEGIN ISOLATION LEVEL SERIALIZABLE; #{sql}; COMMIT;", user: user, allow_failure: true)
        if answer[:status].to_i.zero?
          lines = answer[:stdout].to_s.lines.map(&:strip)
          json = lines.reverse.find { |line| line.start_with?('{') }
          raise 'API returned no JSON' unless json
          return JSON.parse(json)
        end
        retryable = answer[:stderr].to_s.match?(/40001|40P01|could not serialize|deadlock detected/)
        if retryable && attempt < 4
          @retry_events << {method: method, arguments: arguments, attempt: attempt, error: answer[:stderr].to_s[0, 500]}
          next
        end
        raise "API SQL error: #{answer[:stderr]}"
      end
    end

    def buy(tier = 'standard', key = 'purchase-1', target = TARGET, user: 's2_viewer')
      api('purchase', target, tier, key, user: user)
    end

    def read(purpose = 'standard', target = TARGET, user: 's2_viewer')
      api('read_result', target, purpose, user: user, mutate: false)
    end

    def stats(target = TARGET, viewer = VIEWER)
      scalar("SELECT s2_fixture.stats(#{quote(viewer)},#{quote(target)})")
    end

    def state(result, expected)
      assert(result['state'] == expected, "Expected #{expected}, observed #{result.inspect}")
    end

    def gate(value)
      admin("SELECT s2_fixture.set_plus_gate(#{value ? 'true' : 'false'})")
    end

    def no_purchase_effects(target = TARGET)
      observed = stats(target)
      assert(observed['debits'] == 0 && observed['entitlements'] == 0 && observed['snapshots'] == 0,
             "Failed operation left purchase effects: #{observed}")
      observed
    end

    def payload(subject, kind)
      scalar("SELECT s2_fixture.latest_payload(#{quote(subject)},#{quote(kind)})")
    end

    def capture(subject, kind, value, quality = 'validated')
      execute("SELECT s2_private.capture(#{quote(subject)},#{quote(kind)},#{quote(JSON.generate(value))}::jsonb,#{quote(quality)})", allow_failure: true)
    end

    def chapter2_fields(preferences, key)
      preferences['chapter2'].find { |b| b['key'] == key }['fields']
    end

    def set_field(fields, key, value)
      entry = fields.find { |f| f['key'] == key }
      entry ? entry['value'] = value : fields << {'key' => key, 'value' => value}
    end

    def chapter2_parity_case(name, earned_delta:, available_delta:, category_deltas:)
      reset
      baseline = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
      state(baseline, 'success')
      answers = payload(TARGET, 'answers')
      preferences = payload(VIEWER, 'preferences')
      yield(answers, preferences)
      assert(capture(TARGET, 'answers', answers)[:status].to_i.zero?, "#{name}: complete valid target capture rejected")
      assert(capture(VIEWER, 'preferences', preferences)[:status].to_i.zero?, "#{name}: complete valid preference capture rejected")
      actual = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
      state(actual, 'success')
      expected_earned = Rational(baseline['earned_n'].to_i, baseline['earned_d'].to_i) + earned_delta
      assert(Rational(actual['earned_n'].to_i, actual['earned_d'].to_i) == expected_earned, "#{name}: overall earned delta mismatch")
      assert(actual['available'] == baseline['available'] + available_delta, "#{name}: overall denominator delta mismatch")
      baseline['categories'].each do |category, before|
        delta = category_deltas.fetch(category, [Rational(0), 0])
        after = actual['categories'].fetch(category)
        expected = Rational(before['earned_n'].to_i, before['earned_d'].to_i) + delta.first
        assert(Rational(after['earned_n'].to_i, after['earned_d'].to_i) == expected, "#{name}: #{category} earned mismatch")
        assert(after['available'] == before['available'] + delta.last, "#{name}: #{category} denominator mismatch")
      end
      {case: name, expected_earned_delta: earned_delta.to_s, expected_available_delta: available_delta,
       observed_earned: Rational(actual['earned_n'].to_i, actual['earned_d'].to_i).to_s,
       observed_available: actual['available'], full_bank_retained: true}
    end

    def rejected_capture(id, kind: 'answers', subject: TARGET)
      check(id) do
        value = payload(subject, kind)
        changed = yield(value)
        result = capture(subject, kind, changed)
        assert(result[:status].to_i != 0 && result[:stderr].to_s.match?(/22023|invalid|missing|unknown|duplicate|exclusive|variant|unsupported|configuration/i),
               "Malformed capture was not rejected: #{result}")
        {capture_rejected: true, error: result[:stderr].to_s[0, 600]}
      end
    end

    def deny(id)
      check(id) do
        measurements = yield
        measurements.each do |entry|
          assert(entry[:status].to_i != 0 && entry[:stderr].to_s.include?('permission denied'),
                 "Expected genuine ACL denial, not missing-object/syntax failure: #{entry}")
        end
        {denials_observed: measurements.length}
      end
    end

    def race(*jobs)
      start = Queue.new
      ready = Queue.new
      workers = jobs.map do |job|
        Thread.new do
          ready << true
          start.pop
          job.call
        rescue StandardError => error
          {thread_error: error.message}
        end
      end
      jobs.length.times { ready.pop }
      jobs.length.times { start << true }
      workers.map(&:value)
    end

    def assert_race(results)
      assert(results.none? { |r| r.key?(:thread_error) }, "Concurrent worker failed: #{results}")
    end

    def wait_for_sql(predicate, timeout: 5)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      loop do
        return true if scalar("SELECT to_jsonb(#{predicate})")
        raise 'Controlled concurrency barrier was not reached' if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.03
      end
    end

    def hold_advisory(key, after: nil)
      Thread.new do
        execute("BEGIN; SELECT pg_advisory_xact_lock(#{key}); SELECT pg_sleep(2); #{after}; COMMIT;")
      rescue StandardError => error
        {thread_error: error.message}
      end.tap do
        wait_for_sql("EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=#{key} AND granted)")
      end
    end

    def waiting_role(role, type = 'advisory')
      "EXISTS(SELECT 1 FROM pg_locks l JOIN pg_stat_activity a ON a.pid=l.pid WHERE a.usename=#{quote(role)} AND l.locktype=#{quote(type)} AND NOT l.granted)"
    end

    def restriction_after_preflight(key, mutation)
      admin("INSERT INTO s2_fixture.injections(point,advisory_key) VALUES('snapshots',#{key})")
      holder = hold_advisory(key)
      purchase = Thread.new { buy('standard', "preflight-#{key}") }
      wait_for_sql(waiting_role('s2_viewer'))
      restriction = Thread.new { admin(mutation) }
      holder.value; result = purchase.value; restriction.value
      state(result, 'success'); state(read, 'forbidden')
      assert(stats['debits'] == 1, 'Guarded preflight/restriction ordering changed debit count')
      {preflight_paused_before_commit: true, purchase_guard_won: true, subsequent_read_denied: true, postconditions: stats}
    end

    def run
      input_tests
      access_tests
      permission_tests
      lifecycle_tests
      additional_lifecycle_tests
      concurrency_tests
      inference_probe
      @inventory.each do |item|
        next if @results.any? { |r| r[:id] == item['id'] }
        reason = if item['id'] == 'REV05'
                   'Candidate has no Bio/Profile write path; unrelated-Bio-change isolation requires later authorised app/production integration evidence.'
                 else
                   case item['group']
                 when 'ISO' then 'Runtime/credential/network/baseline inspection belongs to root runner evidence; not asserted by SQL test suite.'
                 when 'OBS' then 'Full observable-transcript inference measurement remains an explicit Stage 3 gate; no privacy-pass placeholder.'
                 when 'REV', 'TX', 'AC' then 'Additional deterministic race/failure-injection schedule not yet measured by this harness.'
                 else 'Named case not implemented or measured by this local candidate run; remains a handover gap.'
                   end
                 end
        record(item['id'], 'pending', reason)
      end
      @results.sort_by { |r| [r[:id][0...-2], r[:id][-2..].to_i] }
    end

    def input_tests
      check('IN01') do
        raw = payload(TARGET, 'answers'); raw['answers'] << raw['answers'].first.dup
        list_result = capture(TARGET, 'answers', raw)
        assert(list_result[:status].to_i != 0 && list_result[:stderr].to_s.match?(/duplicate/), 'Duplicate raw entries accepted')
        multi_raw = payload(TARGET, 'answers')
        definition = @export['manifest']['answers'].find do |q|
          q['selection'] == 'multi' && multi_raw['answers'].any? { |a| a['key'] == q['key'] }
        end
        raise 'Applicable multi-select fixture absent' unless definition
        answer = multi_raw['answers'].find { |a| a['key'] == definition['key'] }
        selected = Array(answer['value']).first
        answer['value'] = [selected, selected]
        option_result = capture(TARGET, 'answers', multi_raw)
        assert(option_result[:status].to_i != 0 && option_result[:stderr].to_s.include?('duplicate option'), 'Duplicate selected options accepted')
        json_text = '{"answers":[],"answers":[],"chapter2":[]}'
        text_result = execute("SELECT s2_private.capture_text('#{TARGET}','answers',#{quote(json_text)})", allow_failure: true)
        assert(text_result[:status].to_i != 0 && text_result[:stderr].to_s.include?('duplicate object member'), 'Duplicate JSON object member lost before validation')
        {duplicate_list_rejected: true, duplicate_selected_options_rejected: true, duplicate_object_member_rejected: true}
      end
      check('IN02') do
        definitions = @export['manifest']['answers'].select { |q| q['exclusive_options'].include?('None') }
        assert(definitions.map { |q| q['question_id'] }.sort == %w[ch3_q37 ch3_q97], 'Exclusive None manifest regression')
        definitions.map do |definition|
          raw = payload(TARGET, 'answers')
          answer = raw['answers'].find { |q| q['key'] == definition['key'] }
          other_options = definition['options'].reject { |o| o == 'None' }
          assert(other_options.length >= 2, 'Non-exclusive multi-option regression fixture absent')
          answer['value'] = ['None', other_options.first]
          rejected = capture(TARGET, 'answers', raw)
          assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.include?('exclusive answer conflict'), "#{definition['key']}: None combination not explicitly rejected")
          answer['value'] = other_options.first(2)
          accepted = capture(TARGET, 'answers', raw)
          assert(accepted[:status].to_i.zero?, "#{definition['key']}: valid non-exclusive combination rejected")
          {question: definition['key'], none_combination_rejected: true, ordinary_combination_accepted: true}
        end
      end
      rejected_capture('IN03', kind: 'preferences', subject: VIEWER) { |p| p['controls'].shift; p }
      check('IN04') do
        original_answers = payload(TARGET, 'answers')
        original_preferences = payload(VIEWER, 'preferences')
        observations = []
        unknown_question = Marshal.load(Marshal.dump(original_answers))
        unknown_question['answers'] << {'key' => 'unrecognised-question', 'value' => 'invalid'}
        rejected = capture(TARGET, 'answers', unknown_question)
        assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.include?('unknown or duplicate field'), 'Unknown question was not explicitly rejected')
        observations << {case: 'unknown_question', rejection: rejected[:stderr].to_s.lines.first.to_s.strip}
        definition = @export['manifest']['answers'].find do |q|
          q['selection'] == 'single' && q['parent_key'].nil? && original_answers['answers'].any? { |a| a['key'] == q['key'] }
        end
        raise 'Applicable scalar answer fixture absent' unless definition
        unknown_option = Marshal.load(Marshal.dump(original_answers))
        unknown_option['answers'].find { |a| a['key'] == definition['key'] }['value'] = 'unregistered-answer-option'
        rejected = capture(TARGET, 'answers', unknown_option)
        assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.include?('invalid scalar answer'), 'Unknown answer option was not explicitly rejected')
        observations << {case: 'unknown_scalar_option', question: definition['key'], rejection: rejected[:stderr].to_s.lines.first.to_s.strip}
        ['blue', nil, 1].each do |invalid_light|
          preferences = Marshal.load(Marshal.dump(original_preferences))
          preferences['controls'].first['lights'].first['value'] = invalid_light
          rejected = capture(VIEWER, 'preferences', preferences)
          assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.match?(/unknown duplicate or invalid light|invalid light entry/), 'Invalid light was not explicitly rejected')
          observations << {case: 'invalid_light', value: invalid_light, rejection: rejected[:stderr].to_s.lines.first.to_s.strip}
        end
        assert(payload(TARGET, 'answers') == original_answers && payload(VIEWER, 'preferences') == original_preferences, 'Rejected input changed a valid semantic head')
        {cases: observations, valid_semantic_heads_unchanged: true}
      end
      rejected_capture('IN05') do |p|
        definition = @export['manifest']['answers'].find { |q| q['selection'] == 'multiple' || q['selection'] == 'multi' }
        raise 'No multi-select definition in export' unless definition
        answer = p['answers'].find { |q| q['key'] == definition['key'] }
        raise 'Applicable multi-select fixture missing' unless answer
        answer['value'] = [Array(answer['value']).first, 'not-a-valid-option']; p
      end
      check('IN06') do
        original = payload(TARGET, 'answers')
        assert(original['answers'].any? { |a| a['key'] == 'ch3_q3' && a['value'] == 'Yes' } &&
               original['answers'].any? { |a| a['key'] == 'ch3_q24' }, 'Conditional Yes/child fixture absent')
        observations = []
        validate_case = lambda do |label, expected_rejection, mutation|
          raw = Marshal.load(Marshal.dump(original))
          mutation.call(raw)
          rejected = capture(TARGET, 'answers', raw)
          assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.match?(expected_rejection), "#{label}: expected conditional/variant rejection absent")
          observations << {case: label, rejection: rejected[:stderr].to_s.lines.first.to_s.strip}
        end
        validate_case.call('wrong_q26_variant', /unknown or duplicate field/, lambda do |raw|
          raw['answers'].find { |a| a['key'] == 'ch3_q26::female' }['key'] = 'ch3_q26::male'
        end)
        validate_case.call('missing_q24_parent', /missing required answer|missing parent evidence/, lambda do |raw|
          raw['answers'].reject! { |a| a['key'] == 'ch3_q3' }
        end)
        validate_case.call('invalid_q24_parent_option', /invalid scalar answer/, lambda do |raw|
          raw['answers'].find { |a| a['key'] == 'ch3_q3' }['value'] = 'malformed-conditional-parent'
        end)
        validate_case.call('missing_applicable_q24_child', /missing required answer/, lambda do |raw|
          raw['answers'].reject! { |a| a['key'] == 'ch3_q24' }
        end)
        validate_case.call('stale_q24_child_when_parent_no', /stale hidden answer/, lambda do |raw|
          raw['answers'].find { |a| a['key'] == 'ch3_q3' }['value'] = 'No'
        end)
        assert(payload(TARGET, 'answers') == original, 'Rejected conditional input changed valid semantic head')
        {cases: observations, valid_semantic_head_unchanged: true}
      end
      check('IN07') do
        raw = payload(VIEWER, 'preferences')
        canonical = capture(VIEWER, 'preferences', raw)
        assert(canonical[:status].to_i.zero?, 'Canonical complete preference capture rejected')
        manifest = Marshal.load(Marshal.dump(@export['manifest']))
        definition = manifest['preferences'].find do |q|
          q['target_pool'].include?('female') && raw['controls'].any? { |c| c['id'] == q['id'] }
        end
        raise 'Offered counterpart preference fixture absent' unless definition
        # The current approved bank offers no hard_supported=false controls.
        # This private validator branch probe never installs/captures its clone.
        definition['hard_supported'] = false
        manifest['answers'].find { |q| q['key'] == definition['target_key'] }['hard_supported'] = false
        validate = lambda do |preferences|
          execute("SELECT s2_private.validate_preferences(#{quote(JSON.generate(manifest))}::jsonb,#{quote(JSON.generate(preferences))}::jsonb)", allow_failure: true)
        end
        baseline = validate.call(raw)
        assert(baseline[:status].to_i.zero?, 'Synthetic no-Hard validator baseline rejected')
        raw['controls'].find { |c| c['id'] == definition['id'] }['hards'] = [definition['options'].first]
        rejected = validate.call(raw)
        assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.include?('unsupported hard requirement'),
               'Unsupported Hard did not produce its exact validation rejection')
        {canonical_capture_valid: true, unsupported_hard_rejected: true, control: definition['id'],
         boundary: 'Private-validator branch unit probe only; cloned manifest never installed/captured; canonical manifest pin unchanged.'}
      end
      check('IN08') do
        missing = Marshal.load(Marshal.dump(@export['manifest']))
        missing['answers'].first.delete('category')
        duplicate = Marshal.load(Marshal.dump(@export['manifest']))
        duplicate['answers'] << duplicate['answers'].first.dup
        failures = [missing, duplicate].map do |manifest|
          execute("SELECT s2_private.validate_manifest(#{quote(JSON.generate(manifest))}::jsonb)", allow_failure: true)
        end
        assert(failures.all? { |r| r[:status].to_i != 0 && r[:stderr].to_s.match?(/category|manifest|duplicate/) }, 'Invalid category manifest accepted')
        {invalid_manifest_variants_rejected: failures.length}
      end
      rejected_capture('IN09', kind: 'preferences', subject: VIEWER) do |p|
        control = p['chapter2'].find { |c| c['key'] == 'sect' }
        raise 'Sect fixture absent' unless control
        field = control['fields'].find { |f| f['key'] == 'hard_requirement' }
        raise 'Sect vocabulary field absent' unless field
        field['value'] = ['unknown-custom-sect']; p
      end
      rejected_capture('IN10', kind: 'preferences', subject: VIEWER) do |p|
        hidden = @export['subjects']['female']['preferences']['controls'].find { |c| c['id'] == 'pref:ch3_q26::male' }
        raise 'Opposite q26 alias fixture absent' unless hidden
        p['controls'] << hidden; p
      end
      check('IN11') do
        baseline = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
        value = payload(TARGET, 'answers')
        value['answers'].find { |a| a['key'] == 'ch3_q3' }['value'] = 'No'
        value['answers'].reject! { |a| a['key'] == 'ch3_q24' }
        result = capture(TARGET, 'answers', value); assert(result[:status].to_i.zero?, 'Valid target No conditional capture rejected')
        absent = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
        state(absent, 'success')
        assert(absent['available'] == baseline['available'] - 1, 'Target No did not exclude exactly timing question')
        prefs = payload(VIEWER, 'preferences')
        assert(prefs['controls'].any? { |c| c['id'] == 'pref:ch3_q24' }, 'q24 preference incorrectly hidden by applicability')
        {target_no_denominator_exclusion: 1, q24_preference_still_required: true}
      end
      check('IN12') do
        male_controls = payload(VIEWER, 'preferences')['controls'].map { |c| c['id'] }
        female_controls = payload(TARGET, 'preferences')['controls'].map { |c| c['id'] }
        assert(male_controls.include?('pref:ch3_q26::female') && !male_controls.include?('pref:ch3_q26::male'), 'Male viewer not female-target q26 vocabulary')
        assert(female_controls.include?('pref:ch3_q26::male') && !female_controls.include?('pref:ch3_q26::female'), 'Female viewer not male-target q26 vocabulary')
        %w[male female].map do |sex|
          p = @export['subjects'][sex]['preferences']
          answer = execute("SELECT s2_private.validate_preferences(#{quote(JSON.generate(@export['manifest']))}::jsonb,#{quote(JSON.generate(p))}::jsonb)")
          {viewer_sex: sex, valid_target_variant: answer[:status].to_i.zero?}
        end
      end
      check('IN13') do
        male = payload(VIEWER, 'preferences')['controls'].map { |c| c['id'] }
        female = payload(TARGET, 'preferences')['controls'].map { |c| c['id'] }
        assert(!male.include?('pref:ch3_q39::male') && female.include?('pref:ch3_q39::male'), 'q39 visibility not counterpart-male pool')
        assert(payload(TARGET, 'answers')['answers'].none? { |a| a['key'] == 'ch3_q39::male' }, 'Female own-answer fixture incorrectly received men-only q39')
        {female_viewer_has_preference_without_own_answer: true}
      end
      check('IN14') do
        pref = payload(VIEWER, 'preferences')
        pref['controls'].first['semantics'] = 'legacy-no-preference'
        pref['controls'].first['lights'].first['value'] = 'amber'
        rejected = capture(VIEWER, 'preferences', pref)
        assert(rejected[:status].to_i != 0 && rejected[:stderr].to_s.include?('legacy amber'), 'Legacy Amber silently reinterpreted')
        pref['controls'].first['semantics'] = 'prefer-open-not-for-me-research-v1'
        confirmed = capture(VIEWER, 'preferences', pref)
        assert(confirmed[:status].to_i.zero?, 'Affected control reconfirmation did not repair legacy Amber')
        {affected_control_only_reconfirmed: true}
      end
      check('IN15') do
        pref = payload(VIEWER, 'preferences')
        pref['controls'].each { |c| c.delete('semantics'); c['lights'].each { |l| l['value'] = 'green' } }
        accepted = capture(VIEWER, 'preferences', pref)
        assert(accepted[:status].to_i.zero?, 'Unversioned green-only structurally valid capture required Amber review')
        pref['controls'].first['lights'].pop
        rejected = capture(VIEWER, 'preferences', pref)
        assert(rejected[:status].to_i != 0, 'Unversioned green-only skipped structural validation')
        {no_amber_reset: true, structural_validation_enforced: true}
      end
      check('IN16') do
        observations = []
        observations << chapter2_parity_case('sect_amber_one_half_unit', earned_delta: Rational(-1, 2), available_delta: 0,
          category_deltas: {'deen_practice' => [Rational(-1, 2), 0]}) do |_answers, prefs|
          chapter2_fields(prefs, 'sect').find { |f| f['key'] == 'matrix' }['value'].each { |l| l['value'] = 'amber' }
        end
        observations << chapter2_parity_case('revert_false_excluded', earned_delta: Rational(0), available_delta: 0,
          category_deltas: {}) do |_answers, prefs|
          set_field(chapter2_fields(prefs, 'revert'), 'flexibility', 'red')
        end
        observations << chapter2_parity_case('revert_true_amber_added', earned_delta: Rational(1, 2), available_delta: 1,
          category_deltas: {'deen_practice' => [Rational(1, 2), 1]}) do |answers, prefs|
          set_field(answers['chapter2'], 'revert', true)
          set_field(chapter2_fields(prefs, 'revert'), 'flexibility', 'amber')
        end
        %w[country_of_birth nationality ethnicity].each do |key|
          observations << chapter2_parity_case("#{key}_match_overrides_red_flexibility", earned_delta: Rational(1), available_delta: 1,
            category_deltas: {'culture_language' => [Rational(1), 1]}) do |answers, prefs|
            target_value = answers['chapter2'].find { |f| f['key'] == key }['value']
            fields = chapter2_fields(prefs, key)
            set_field(fields, 'preferred', [target_value]); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'red')
          end
          observations << chapter2_parity_case("#{key}_mismatch_amber_one_half_unit", earned_delta: Rational(1, 2), available_delta: 1,
            category_deltas: {'culture_language' => [Rational(1, 2), 1]}) do |answers, prefs|
            target_value = answers['chapter2'].find { |f| f['key'] == key }['value']
            alternative = @export['manifest']['chapter2_vocabulary'].fetch(key).find { |v| v != target_value }
            assert(alternative, "#{key}: nonmatching registered synthetic value absent")
            fields = chapter2_fields(prefs, key)
            set_field(fields, 'preferred', [alternative]); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'amber')
          end
        end
        observations << chapter2_parity_case('english_only_language_excluded', earned_delta: Rational(0), available_delta: 0,
          category_deltas: {}) do |_answers, prefs|
          fields = chapter2_fields(prefs, 'languages')
          set_field(fields, 'preferred', ['en']); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'red')
        end
        observations << chapter2_parity_case('language_any_nonenglish_overlap_one_unit', earned_delta: Rational(1), available_delta: 1,
          category_deltas: {'culture_language' => [Rational(1), 1]}) do |answers, prefs|
          spoken = answers['chapter2'].find { |f| f['key'] == 'languages' }['value'].find { |v| v != 'en' }
          assert(spoken, 'Registered non-English target language absent')
          fields = chapter2_fields(prefs, 'languages')
          set_field(fields, 'preferred', ['en', spoken]); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'red')
        end
        observations << chapter2_parity_case('language_no_overlap_amber_one_half_unit', earned_delta: Rational(1, 2), available_delta: 1,
          category_deltas: {'culture_language' => [Rational(1, 2), 1]}) do |answers, prefs|
          spoken = answers['chapter2'].find { |f| f['key'] == 'languages' }['value']
          alternative = @export['manifest']['chapter2_vocabulary']['languages'].find { |v| v != 'en' && !spoken.include?(v) }
          assert(alternative, 'Registered nonmatching language absent')
          fields = chapter2_fields(prefs, 'languages')
          set_field(fields, 'preferred', [alternative]); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'amber')
        end
        observations << chapter2_parity_case('empty_and_explicit_skip_excluded', earned_delta: Rational(0), available_delta: 0,
          category_deltas: {}) do |_answers, prefs|
          %w[country_of_birth nationality ethnicity languages].each_with_index do |key, index|
            fields = chapter2_fields(prefs, key)
            set_field(fields, 'preferred', []); set_field(fields, 'skipped', index.even?); set_field(fields, 'flexibility', 'red')
          end
        end
        observations << chapter2_parity_case('all_six_chapter2_controls_provisional_weight_one', earned_delta: Rational(4), available_delta: 5,
          category_deltas: {'deen_practice' => [Rational(0), 1], 'culture_language' => [Rational(4), 4]}) do |answers, prefs|
          set_field(answers['chapter2'], 'revert', true)
          chapter2_fields(prefs, 'sect').find { |f| f['key'] == 'matrix' }['value'].each { |l| l['value'] = 'amber' }
          set_field(chapter2_fields(prefs, 'revert'), 'flexibility', 'amber')
          %w[country_of_birth nationality ethnicity languages].each do |key|
            target_value = answers['chapter2'].find { |f| f['key'] == key }['value']
            preferred = key == 'languages' ? target_value.reject { |v| v == 'en' } : [target_value]
            fields = chapter2_fields(prefs, key)
            set_field(fields, 'preferred', preferred); set_field(fields, 'skipped', false); set_field(fields, 'flexibility', 'red')
          end
        end
        {boundary: 'Hand-derived Chapter2 raw-contribution deltas on otherwise complete unchanged full-bank fixtures; provisional weight 1 only.', cases: observations}
      end
      check('IN17') do
        baseline = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
        answer = payload(TARGET, 'answers')
        location = answer['chapter2'].find { |f| f['key'] == 'location' }
        location ? location['value'] = 'Different Synthetic Place' : answer['chapter2'] << {'key' => 'location', 'value' => 'Different Synthetic Place'}
        assert(capture(TARGET, 'answers', answer)[:status].to_i.zero?, 'Valid unscored location rejected')
        prefs = payload(VIEWER, 'preferences')
        sect = prefs['chapter2'].find { |f| f['key'] == 'sect' }
        flex = sect['fields'].find { |f| f['key'] == 'outside_flexibility' }
        flex ? flex['value'] = 'red' : sect['fields'] << {'key' => 'outside_flexibility', 'value' => 'red'}
        assert(capture(VIEWER, 'preferences', prefs)[:status].to_i.zero?, 'Valid unscored outside flexibility rejected')
        after = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
        %w[earned_n earned_d available categories].each { |f| assert(after[f] == baseline[f], "Unscored controls changed #{f}") }
        {location_and_outside_flexibility_unscored: true}
      end
      check('IN18') do
        result = scalar("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')")
        state(result, 'success')
        categories = result['categories'].values
        available = categories.sum { |v| v['available'] }
        earned = categories.sum { |v| Rational(v['earned_n'].to_i, v['earned_d'].to_i) }
        assert(available == result['available'], 'Category available totals do not reconcile')
        assert(earned == Rational(result['earned_n'].to_i, result['earned_d'].to_i), 'Raw category earned totals do not reconcile')
        {earned: earned.to_s, available: available, categories: categories.length}
      end
      check('IN19') do
        prefs = payload(VIEWER, 'preferences')
        prefs['controls'].each { |c| c['hards'] = []; c['lights'].each { |l| l['value'] = 'red' } }
        prefs['chapter2'].each do |block|
          case block['key']
          when 'sect'
            block['fields'].each do |f|
              f['value'].each { |l| l['value'] = 'red' } if f['key'] == 'matrix'
              f['value'] = [] if f['key'] == 'hard_requirement'
            end
          when 'revert'
            block['fields'].find { |f| f['key'] == 'flexibility' }['value'] = 'red'
          else
            block['fields'].find { |f| f['key'] == 'preferred' }['value'] = []
            block['fields'].find { |f| f['key'] == 'skipped' }['value'] = true
          end
        end
        assert(capture(VIEWER, 'preferences', prefs)[:status].to_i.zero?, 'All-red valid input rejected')
        result = buy
        state(result, 'success')
        assert(result['overall_percentage'] == 0, 'Valid zero score treated as missing/unavailable')
        {valid_zero: result}
      end
      check('IN20') do
        directions = [['male_to_female', VIEWER, TARGET], ['female_to_male', TARGET, VIEWER], ['mixed_male_to_female', VIEWER, TARGET]]
        directions.map do |name, viewer, target|
          if name == 'mixed_male_to_female'
            captured = capture(VIEWER, 'preferences', @export['mixed_preferences'])
            assert(captured[:status].to_i.zero?, 'Mixed-light parity fixture invalid')
          end
          actual = scalar("SELECT s2_private.calculate(#{quote(viewer)},#{quote(target)})")
          state(actual, 'success')
          expected = @export['oracles'].fetch(name)
          %w[earned_n earned_d available categories].each do |field|
            assert(actual[field] == expected[field], "#{name} differs from Stage 1 parity oracle at #{field}")
          end
          {direction: name, earned_n: actual['earned_n'], earned_d: actual['earned_d'], available: actual['available']}
        end
      end
    end

    def access_tests
      check('AC01') { admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false)"); state(buy, 'forbidden'); no_purchase_effects }
      check('AC07') do
        state(buy, 'success')
        admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',false,true)")
        state(read, 'forbidden')
        assert(stats['entitlements'] == 1 && stats['debits'] == 1, 'Safety restriction altered permanent purchase effects')
        stats
      end
      check('AC08') do
        state(buy, 'success')
        admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false)")
        state(read, 'forbidden')
        assert(stats['entitlements'] == 1, 'Block removed permanent entitlement')
        stats
      end
      check('AC09') do
        state(buy('standard', 'owned-key'), 'success')
        other = buy('standard', 'owned-key', TARGET, user: 's2_other')
        assert(other['state'] != 'success', 'Different actor recovered previous private outcome')
        other
      end
      check('AC11') do
        state(buy('standard', 'committed-before-revocation'), 'success')
        admin("SELECT s2_fixture.set_subject('#{TARGET}','deleted',false)")
        state(read, 'forbidden')
        assert(stats['debits'] == 1, 'Post-commit deletion charged again')
        stats
      end
      check('AC12') do
        gate(true); state(buy('plus'), 'success'); initial = stats['current_snapshot_id']
        admin("SELECT s2_fixture.set_guardian('#{TARGET}','Changed Synthetic Guardian','Brother','Changed Synthetic City',false,'linked')")
        updated = read('plus')
        assert(updated['guardian']['first_name'] == 'Changed Synthetic Guardian' && updated['guardian']['relationship'] == 'Brother', 'Current Guardian relationship stale')
        admin("SELECT s2_fixture.set_guardian('#{TARGET}',NULL,NULL,NULL,false,'unlinked')")
        removed = read('plus')
        assert(removed['guardian']['state'] == 'unlinked' && !removed['guardian'].key?('first_name'), 'Removed Guardian details still displayed')
        assert(stats['current_snapshot_id'] == initial, 'Guardian update refreshed calculation')
        {updated: updated['guardian'], removed: removed['guardian']}
      end
    end

    def permission_tests
      check('ACL01') do
        matrix = scalar("SELECT jsonb_agg(jsonb_build_object('role',r.rolname,'table',c.relname,'select',has_table_privilege(r.oid,c.oid,'SELECT'),'insert',has_table_privilege(r.oid,c.oid,'INSERT'),'update',has_table_privilege(r.oid,c.oid,'UPDATE'),'delete',has_table_privilege(r.oid,c.oid,'DELETE'))) FROM pg_roles r CROSS JOIN pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE r.rolname IN ('s2_anon','s2_viewer','s2_target','s2_other','s2_guardian') AND n.nspname='s2_private' AND c.relkind IN ('r','v','m')")
        assert(matrix.all? { |v| !v['select'] && !v['insert'] && !v['update'] && !v['delete'] }, 'Private role/resource grant leak')
        {matrix_cells: matrix.length, private_access_grants: 0}
      end
      deny('ACL02') { ROLES.map { |r| execute("SELECT s2_private.calculate('#{VIEWER}','#{TARGET}')", user: r, allow_failure: true) } }
      deny('ACL03') { %w[snapshots input_evidence input_revisions].product(ROLES).map { |t, r| execute("SELECT * FROM s2_private.#{t}", user: r, allow_failure: true) } }
      check('ACL04') do
        leaks = scalar("SELECT coalesce(jsonb_agg(c.relname),'[]'::jsonb) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('s2_private','s2_fixture') AND c.relkind IN ('v','m','S') AND (has_table_privilege('s2_viewer',c.oid,'SELECT') OR has_table_privilege('s2_anon',c.oid,'SELECT'))")
        assert(leaks.empty?, "Leaking views/sequences #{leaks}")
        {leaking_views_or_sequences: leaks}
      end
      check('ACL05') do
        leaks = scalar("SELECT coalesce(jsonb_agg(p.proname),'[]'::jsonb) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a WHERE n.nspname IN ('s2_private','s2_api','s2_fixture') AND a.grantee=0 AND a.privilege_type='EXECUTE'")
        assert(leaks.empty?, "PUBLIC execute leak #{leaks}")
        denied = execute("SELECT s2_api.purchase('#{TARGET}','standard','anon')", user: 's2_anon', allow_failure: true)
        assert(denied[:status].to_i != 0 && denied[:stderr].to_s.include?('permission denied'), 'Anonymous execute not denied')
        {public_execute_functions: leaks, anonymous_denied: true}
      end
      check('ACL06') do
        bad = scalar("SELECT coalesce(jsonb_agg(p.proname),'[]'::jsonb) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('s2_private','s2_api') AND p.prosecdef AND NOT EXISTS(SELECT 1 FROM unnest(p.proconfig) x WHERE x LIKE 'search_path=pg_catalog,%' AND x NOT LIKE '%public%')")
        assert(bad.empty?, "Unsafe SECURITY DEFINER search_path #{bad}")
        created = execute('CREATE TEMP TABLE subjects(subject_id text,db_role name);', user: 's2_viewer', allow_failure: true)
        if created[:status].to_i.zero?
          result = scalar("CREATE TEMP TABLE subjects(subject_id text,db_role name); INSERT INTO subjects VALUES('synthetic-other','s2_viewer'); SELECT s2_api.read_result('#{TARGET}','standard');", user: 's2_viewer')
          assert(result['state'] != 'success', 'Temporary object shadow changed private authority')
          {fixed_paths: true, temp_shadow_denied: true}
        else
          assert(created[:stderr].to_s.include?('permission denied'), 'Unexpected temp creation error')
          {fixed_paths: true, temp_creation_denied: true}
        end
      end
      check('ACL07') do
        state(buy, 'success')
        forged = scalar("SET request.jwt.claim.sub='synthetic-viewer'; SET request.jwt.claims='{\"sub\":\"synthetic-viewer\"}'; SELECT s2_api.read_result('#{TARGET}','standard');", user: 's2_other')
        assert(forged['state'] != 'success', 'Client GUC forged actor')
        forged
      end
      check('ACL08') do
        unknown = buy('plus-test-bypass')
        assert(unknown['state'] != 'success', 'Client tier bypass accepted')
        no_purchase_effects
      end
      deny('ACL09') { [execute('UPDATE s2_private.configuration SET plus_enabled=true', user: 's2_viewer', allow_failure: true), execute('SELECT s2_fixture.set_plus_gate(true)', user: 's2_viewer', allow_failure: true)] }
      deny('ACL10') { [execute('SET ROLE s2_owner', user: 's2_viewer', allow_failure: true), execute('SET SESSION AUTHORIZATION s2_other', user: 's2_viewer', allow_failure: true)] }
      check('ACL11') do
        state(buy, 'success')
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('synthetic-guardian','#{TARGET}','standard')")
        result = read('standard', TARGET, user: 's2_guardian')
        assert(result['state'] != 'success', 'Guardian inherited viewer compatibility entitlement')
        result
      end
      deny('ACL12') { [execute("SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','defect','authority')", user: 's2_viewer', allow_failure: true), execute('SELECT s2_fixture.purge_evidence(1)', user: 's2_viewer', allow_failure: true), execute('SELECT s2_fixture.reset()', user: 's2_viewer', allow_failure: true)] }
    end

    def lifecycle_tests
      check('REC01') { state(buy('standard', 'shape-key'), 'success'); state(buy('plus', 'shape-key'), 'conflict'); assert(stats['debits'] == 1, 'Conflict debited'); stats }
      check('REC02') { state(buy('standard', 'lost-response'), 'success'); state(buy('standard', 'lost-response'), 'success'); assert(stats['debits'] == 1 && stats['snapshots'] == 1, 'Retry changed effects'); stats }
      check('REC03') do
        state(buy('standard', 'block-retry'), 'success')
        admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false)")
        result = buy('standard', 'block-retry')
        state(result, 'forbidden')
        assert(!result.key?('overall_percentage') && !result.key?('projection'), 'Sensitive cached payload on forbidden retry')
        assert(stats['debits'] == 1, 'Forbidden retry charged')
        result
      end
      check('REC04') do
        state(buy('standard', 'repair-retry'), 'success'); original = read['overall_percentage']; previous_id = stats['current_snapshot_id']
        pref = payload(VIEWER, 'preferences'); pref['controls'].each { |c| c['lights'].each { |l| l['value'] = 'red' } }
        assert(capture(VIEWER, 'preferences', pref)[:status].to_i.zero?, 'Valid later inputs could not be captured')
        repair = scalar("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','scoring_defect','synthetic-authority'); COMMIT;")
        state(repair, 'success')
        result = buy('standard', 'repair-retry'); state(result, 'success')
        assert(result['overall_percentage'] == original && stats['current_snapshot_id'] != previous_id && stats['debits'] == 1 && stats['repair_rows'] == 1, 'Repair substituted current inputs, old binding or repeat debit')
        {original_score_reproduced: original, new_current_snapshot: stats['current_snapshot_id'], repeat_debit: false}
      end
      check('REC05') do
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('#{VIEWER}','#{TARGET}','standard')")
        result = buy('standard', 'held-no-snapshot')
        assert(%w[success recovery_required unavailable repair_required].include?(result['state']), 'Missing held snapshot not typed')
        assert(stats['debits'] == 0, 'Held entitlement charged again')
        {result: result, stats: stats}
      end
      check('REC06') do
        api('reveal_journey', TARGET, 'journey-only')
        admin("DELETE FROM s2_private.journeys WHERE viewer='#{VIEWER}' AND target='#{TARGET}'")
        result = read
        assert(result['state'] != 'success', 'Snapshot alone bypassed entitlement/purpose authority')
        result
      end
      check('REC08') do
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('#{VIEWER}','#{TARGET}','standard')")
        result = api('legacy_transition', TARGET, 'legacy-1')
        state(result, 'success')
        assert(stats['debits'] == 0 && stats['snapshots'] == 1, 'Legacy conversion charged or wrong snapshot count')
        stats
      end
      check('REC09') do
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('#{VIEWER}','#{TARGET}','standard')")
        good = payload(VIEWER, 'preferences')
        bad = Marshal.load(Marshal.dump(good)); bad['controls'].shift
        raw = capture(VIEWER, 'preferences', bad, 'legacy_repair')
        assert(raw[:status].to_i.zero?, 'Legacy-repair fixture could not be stored')
        failed = api('legacy_transition', TARGET, 'legacy-invalid')
        assert(%w[repair_required unavailable].include?(failed['state']), 'Invalid legacy preferences scored')
        fixed = capture(VIEWER, 'preferences', good)
        assert(fixed[:status].to_i.zero?, 'Necessary legacy repair failed')
        state(api('legacy_transition', TARGET, 'legacy-fixed'), 'success')
        assert(stats['debits'] == 0 && stats['snapshots'] == 1, 'Legacy repair retry charged or published provisional snapshot')
        stats
      end
      check('REC11') do
        state(buy, 'success'); id = stats['current_snapshot_id']
        admin("SELECT s2_fixture.purge_evidence(#{id})")
        repair = scalar("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','scoring_defect','synthetic-authority'); COMMIT;")
        assert(repair['state'] != 'success', 'Irreproducible technical repair used current inputs')
        assert(stats['debits'] == 1 && stats['entitlements'] == 1, 'Failed technical repair altered entitlement/debit')
        {result: repair, stats: stats}
      end
      check('REC12') do
        state(buy, 'success'); initial = stats['current_snapshot_id']; admin("SELECT s2_fixture.purge_evidence(#{initial})")
        pref = payload(VIEWER, 'preferences'); pref['controls'].each { |c| c['lights'].each { |l| l['value'] = 'red' } }
        assert(capture(VIEWER, 'preferences', pref)[:status].to_i.zero?, 'Valid current preference revision failed')
        repair = scalar("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','broken_mapping','synthetic-authority'); COMMIT;")
        state(repair, 'unavailable'); state(read, 'unavailable')
        assert(stats['snapshots'] == 1 && stats['current_snapshot_id'] == initial && stats['debits'] == 1, 'Purged evidence allowed substitution/recharge')
        stats
      end
      check('REC13') do
        state(buy, 'success'); admin("DELETE FROM s2_private.wallets WHERE actor='#{VIEWER}'")
        state(read, 'success'); assert(stats['balance'].nil? && stats['debits'] == 1, 'Read created wallet or charged')
        stats
      end
      check('REC14') do
        value = payload(TARGET, 'answers'); value['answers'].shift
        result = capture(TARGET, 'answers', value, 'legacy_repair')
        assert(result[:status].to_i.zero?, 'Invalid legacy target fixture failed to load')
        state(buy, 'unavailable'); no_purchase_effects
      end
      check('PR01') do
        result = read('browse')
        assert(!result.key?('overall_percentage') && !result.key?('categories') && !result.key?('projection'), 'Browse leaked raw compatibility')
        no_purchase_effects
      end
      check('PR02') do
        state(buy, 'success'); result = read
        assert(result.key?('overall_percentage') && !result.key?('categories') && !result.key?('projection'), 'Standard projection field leak')
        assert(!result.key?('counterpart_percentage'), 'Counterpart score exposed')
        result
      end
      check('PR03') do
        gate(true); state(buy, 'success'); before = stats['current_snapshot_id']; state(buy('plus', 'plus-1'), 'success')
        result = read('plus'); state(result, 'success')
        assert(stats['current_snapshot_id'] == before && stats['snapshots'] == 1, 'Plus recalculated snapshot')
        projection = JSON.generate(result['projection'])
        assert(!projection.match?(/earned_n|earned_d|available_count|denominator|question_count|category_percentage/), 'Plus projection exposes private totals')
        {projection: result['projection'], same_snapshot: before}
      end
      check('PR04') do
        state(buy, 'success'); before = stats['current_snapshot_id']; state(api('reveal_journey', TARGET, 'journey-1'), 'success')
        assert(stats['snapshots'] == 1 && stats['current_snapshot_id'] == before && stats['debits'] == 1, 'Journey created new basis/debit')
        stats
      end
      check('PR05') do
        before = scalar("SELECT to_jsonb(j) FROM s2_private.journeys j WHERE viewer='#{VIEWER}' AND target='#{TARGET}'")
        state(api('reveal_journey', TARGET, 'journey-read'), 'success'); read('journey')
        after = scalar("SELECT to_jsonb(j) FROM s2_private.journeys j WHERE viewer='#{VIEWER}' AND target='#{TARGET}'")
        assert(before == after, 'Compatibility read changed Journey stage/flags/attempt')
        {journey_unchanged: true}
      end
      check('PR08') do
        gate(true); state(buy('plus', 'first-plus'), 'success'); pinned = stats['policy']
        admin("UPDATE s2_private.configuration SET policy_version='synthetic-policy-v2',allowed_categories=ARRAY[]::text[],revision=revision+1 WHERE id=1")
        state(buy('plus', 'first-plus'), 'success')
        assert(stats['policy'] == pinned, 'Lost-response retry reprojected policy')
        {pinned_policy: pinned, stats: stats}
      end
      check('PR09') do
        gate(true); state(buy('plus', 'plus-held'), 'success'); prior = read('plus')['projection']
        admin("UPDATE s2_private.configuration SET policy_version='synthetic-policy-v2',revision=revision+1 WHERE id=1")
        state(buy('plus', 'new-operation-key'), 'success')
        assert(read('plus')['projection'] == prior && stats['snapshots'] == 1, 'New key/policy exposed richer projection')
        stats
      end
      check('PR10') do
        gate(true); state(buy('plus', 'plus-guardian'), 'success')
        snapshot_id = stats['current_snapshot_id']
        admin("UPDATE s2_private.guardians SET lookup_state='unavailable' WHERE target='#{TARGET}'")
        result = read('plus'); state(result, 'success')
        assert(result['guardian'] == {'state' => 'unavailable'}, 'Lookup failure not represented by the exact unavailable Guardian state')
        assert(stats['current_snapshot_id'] == snapshot_id && stats['snapshots'] == 1 && stats['debits'] == 1 && stats['entitlements'] == 1,
               'Guardian lookup failure recalculated, recharged or removed entitlement')
        {result: result, same_snapshot: true, repeat_debit: false}
      end
      check('PR12') do
        gate(true); state(buy('plus', 'all-surfaces'), 'success'); first = stats['current_snapshot_id']
        3.times { read('plus'); read('standard'); api('reveal_journey', TARGET, 'same-journey-key') }
        assert(stats['snapshots'] == 1 && stats['current_snapshot_id'] == first && stats['debits'] == 1, 'Repeated surfaces recalculated/debited')
        stats
      end
      check('VAL01') { gate(true); admin("UPDATE s2_private.configuration SET allowed_categories=ARRAY[]::text[] WHERE id=1"); assert(buy('plus')['state'] != 'success', 'All-suppressed Plus accepted'); no_purchase_effects }
      check('VAL02') { gate(true); admin("UPDATE s2_private.configuration SET allowed_categories=ARRAY[]::text[] WHERE id=1"); result = buy('plus'); assert(result['state'] != 'success', 'Guardian-only Plus charged'); no_purchase_effects }
      check('VAL03') do
        gate(true); category = @export['manifest']['categories'].first
        admin("UPDATE s2_private.configuration SET allowed_categories=ARRAY[#{quote(category)}],min_categories=2 WHERE id=1")
        denied = buy('plus', 'one-category-denied'); assert(denied['state'] != 'success', 'Synthetic usefulness predicate ignored')
        assert(stats['debits'] == 0, 'Failed one-category preflight charged')
        admin('UPDATE s2_private.configuration SET min_categories=1 WHERE id=1')
        accepted = buy('plus', 'one-category-accepted'); state(accepted, 'success')
        {synthetic_threshold_two_denied: denied['state'], synthetic_threshold_one_accepted: true}
      end
      check('VAL04') { gate(true); state(buy('plus'), 'success'); assert(stats['debits'] == 1, 'Positive local Plus debit incorrect'); stats }
      check('VAL06') { state(buy('plus'), 'plus_disabled'); no_purchase_effects }
      check('VAL07') { gate(true); state(buy('plus'), 'success'); assert(stats['debits'] == 1, 'Ordinary synthetic enabled Plus failed'); stats }
      check('VAL08') { state(buy('plus'), 'plus_disabled'); no_purchase_effects }
      check('VAL09') { result = buy('standard', 'demo-buy', TARGET, user: 's2_demo'); assert(result['state'] != 'success', 'Presentation demo fixture entered purchase path'); scalar("SELECT jsonb_build_object('debits',count(*)) FROM s2_private.ledger WHERE actor='synthetic-demo' AND kind='debit'").tap { |s| assert(s['debits'] == 0, 'Demo fixture debited') } }
      check('LIFE01') { state(buy, 'success'); admin("SELECT s2_fixture.purge_evidence(#{stats['current_snapshot_id']})"); assert(stats['entitlements'] == 1 && stats['debits'] == 1, 'Evidence purge changed ownership'); stats }
      check('LIFE02') { state(buy, 'success'); first = stats['current_snapshot_id']; admin("SELECT s2_fixture.purge_evidence(#{first})"); state(read, 'success'); state(buy('standard', 'after-purge'), 'success'); assert(stats['snapshots'] == 1 && stats['current_snapshot_id'] == first, 'Evidence purge enabled refresh'); stats }
      check('LIFE03') do
        state(buy, 'success')
        repair = scalar("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','scoring_defect','synthetic-authority'); COMMIT;")
        state(repair, 'success')
        result = read; state(result, 'success')
        assert(!result.key?('history') && !result.key?('snapshot_id') && !result.key?('previous_score'), 'Historical repair comparison exposed')
        deny_old = execute('SELECT * FROM s2_private.snapshots WHERE snapshot_id=1', user: 's2_viewer', allow_failure: true)
        assert(deny_old[:status].to_i != 0 && deny_old[:stderr].to_s.include?('permission denied'), 'Old snapshot selectable')
        stats
      end
      check('LIFE04') { state(buy, 'success'); admin("SELECT s2_fixture.set_subject('#{TARGET}','deleted',false)"); state(read, 'forbidden'); assert(stats['entitlements'] == 1, 'Synthetic deletion removed permanent receipt'); stats }
      check('LIFE05') { 3.times { |i| state(buy('plus', "failed-#{i}"), 'plus_disabled') }; assert(stats['snapshots'] == 0 && stats['evidence_rows'] == 0, 'Failed candidates retained payload archive'); stats }
      check('REV07') do
        state(buy, 'success'); first = read['overall_percentage']; id = stats['current_snapshot_id']
        pref = payload(VIEWER, 'preferences'); pref['controls'].each { |c| c['lights'].each { |l| l['value'] = 'red' } }
        result = capture(VIEWER, 'preferences', pref)
        assert(result[:status].to_i.zero?, 'Valid preference revision could not be captured')
        assert(read['overall_percentage'] == first && stats['current_snapshot_id'] == id && stats['snapshots'] == 1, 'Ordinary edit refreshed result')
        stats
      end
    end

    def concurrency_tests
      [['TX03','identical-key','identical-key'],['TX04','different-a','different-b']].each do |id, key1, key2|
        check(id) do
          retry_start = @retry_events.length
          result = race(-> { buy('standard', key1) }, -> { buy('standard', key2) })
          assert_race(result); result.each { |r| state(r, 'success') }
          observed = stats
          assert(observed['snapshots'] == 1 && observed['entitlements'] == 1 && observed['debits'] == 1 && observed['balance'] == 3, 'Concurrent same-target duplicated effects')
          {responses: result, postconditions: observed, retries: @retry_events[retry_start..].dup}
        end
      end
      check('TX05') do
        retry_start = @retry_events.length
        admin("TRUNCATE s2_private.ledger RESTART IDENTITY; UPDATE s2_private.wallets SET balance=1 WHERE actor='#{VIEWER}'; INSERT INTO s2_private.ledger(actor,amount,kind) VALUES('#{VIEWER}',1,'grant')")
        responses = race(-> { buy('standard', 'target-a', TARGET) }, -> { buy('standard', 'target-b', TARGET2) })
        assert_race(responses)
        assert(responses.count { |r| r['state'] == 'success' } == 1 && responses.count { |r| r['state'] == 'insufficient_credit' } == 1, 'Different-target race overspent/not typed')
        final = scalar("SELECT jsonb_build_object('balance',(SELECT balance FROM s2_private.wallets WHERE actor='#{VIEWER}'),'ledger',sum(amount),'debits',count(*) FILTER(WHERE kind='debit')) FROM s2_private.ledger WHERE actor='#{VIEWER}'")
        assert(final['balance'] == 0 && final['ledger'] == 0 && final['debits'] == 1, 'Different-target race balance/ledger incorrect')
        {responses: responses, postconditions: final, retries: @retry_events[retry_start..].dup}
      end
      check('TX01') do
        gate(true); result = race(-> { buy('standard', 'standard-race') }, -> { buy('plus', 'plus-race') })
        assert_race(result); result.each { |r| state(r, 'success') }
        assert(stats['snapshots'] == 1 && [1,2].include?(stats['entitlements']) && stats['debits'] == stats['entitlements'], 'Standard/Plus race not one basis/per-tier fixture debit')
        {responses: result, postconditions: stats}
      end
      check('TX02') do
        gate(true); result = race(-> { buy('plus', 'plus-journey-race') }, -> { api('reveal_journey', TARGET, 'journey-plus-race') })
        assert_race(result); result.each { |r| state(r, 'success') }
        assert(stats['snapshots'] == 1 && stats['debits'] == 1, 'Plus/Journey race recalculated/charged Journey')
        {responses: result, postconditions: stats}
      end
      check('TX06') do
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('#{VIEWER}','#{TARGET}','standard')")
        result = race(-> { api('legacy_transition', TARGET, 'legacy-race') }, -> { buy('standard', 'held-paid-race') })
        assert_race(result)
        assert(stats['snapshots'] == 1 && stats['debits'] == 0, 'Legacy/held purchase race repeated charge/basis')
        {responses: result, postconditions: stats}
      end
      check('TX16') do
        gate(true)
        result = race(-> { buy('standard', 'three-standard') }, -> { buy('plus', 'three-plus') },
                      -> { api('reveal_journey', TARGET, 'three-journey') })
        assert_race(result); result.each { |r| state(r, 'success') }
        observed = stats
        assert(observed['snapshots'] == 1 && observed['bindings'] == 1 && [1,2].include?(observed['debits']), 'Concurrent initial purposes created more than one basis or extra debit')
        assert(observed['policy'] == 'synthetic-policy-v1', 'First Plus projection was not bound')
        percentages = result.map { |r| r['overall_percentage'] }
        assert(percentages.uniq.length == 1, 'First-purpose race returned different directional results')
        {responses: result, postconditions: observed}
      end
      check('TX07') do
        state(buy, 'success'); old = stats['current_snapshot_id']
        results = race(-> { scalar("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_fixture.repair_snapshot('#{VIEWER}','#{TARGET}','scoring_defect','synthetic-authority'); COMMIT;") }, -> { read })
        assert_race(results); results.each { |r| state(r, 'success') }
        assert(stats['snapshots'] == 2 && stats['current_snapshot_id'] != old && stats['debits'] == 1, 'Repair/read race violated binding or debit')
        {responses: results, postconditions: stats}
      end
      check('TX08') do
        responses = race(-> { admin("SELECT s2_fixture.grant_credit('#{VIEWER}',1)"); {'state'=>'grant_committed'} }, -> { buy('standard', 'grant-race') })
        assert_race(responses)
        observed = stats
        assert(observed['balance'] == 4 && observed['ledger_balance'] == 4 && observed['debits'] == 1, 'Concurrent grant/debit divergence')
        {responses: responses, postconditions: observed}
      end
      check('TX09') do
        state(buy('standard', 'original-paid'), 'success')
        operation = scalar("SELECT to_jsonb(operation_id) FROM s2_private.operations WHERE actor='#{VIEWER}' AND idempotency_key='original-paid'")
        responses = race(-> { admin("SELECT s2_fixture.refund_credit('#{VIEWER}',#{operation})"); {'state'=>'refund_committed'} }, -> { buy('standard', 'refund-race-target', TARGET2) })
        assert_race(responses)
        observed = stats
        assert(observed['balance'] == 3 && observed['ledger_balance'] == 3, 'Concurrent refund/debit divergence')
        {responses: responses, postconditions: observed}
      end
      check('TX10') do
        gate(true)
        admin("INSERT INTO s2_fixture.injections(point,advisory_key) VALUES('snapshots',71010)")
        holder = hold_advisory(71010)
        purchase = Thread.new { buy('plus', 'gate-after-preflight') }
        wait_for_sql(waiting_role('s2_viewer'))
        gate_off = Thread.new { admin('SELECT s2_fixture.set_plus_gate(false)') }
        holder.value; result = purchase.value; gate_off.value
        state(result, 'success')
        assert(scalar('SELECT to_jsonb(plus_enabled) FROM s2_private.configuration WHERE id=1') == false, 'Waiting gate-off did not apply')
        assert(stats['debits'] == 1, 'In-flight purchase/gate ordering debit incorrect')
        denied = buy('plus', 'gate-new-target', TARGET2)
        state(denied, 'plus_disabled')
        {guarded_purchase_committed_first: true, later_target_denied: true, postconditions: stats}
      end
      check('TX11') do
        holder = hold_advisory(71011, after: "UPDATE s2_private.subjects SET revision=revision+1 WHERE subject_id='#{TARGET}'")
        prepared = Thread.new do
          execute("\\set VERBOSITY verbose\nBEGIN ISOLATION LEVEL SERIALIZABLE; SELECT pg_advisory_xact_lock(71011); SELECT s2_api.purchase('#{TARGET}','standard','retry-whole-operation'); COMMIT;", user: 's2_viewer', allow_failure: true)
        end
        wait_for_sql(waiting_role('s2_viewer'))
        holder.value; failure = prepared.value
        assert(failure[:status].to_i != 0 && failure[:stderr].to_s.include?('40001'), 'Controlled stale snapshot did not produce serialization failure')
        no_purchase_effects
        result = buy('standard', 'retry-whole-operation'); state(result, 'success')
        assert(stats['debits'] == 1 && stats['snapshots'] == 1, 'Whole-operation retry duplicated effects')
        {observed_sqlstate: '40001', subsequent_full_retry: result, postconditions: stats}
      end
      check('TX14') do
        observations = %w[snapshots entitlements ledger disclosure_bindings operations].map do |point|
          reset; gate(true)
          admin("INSERT INTO s2_fixture.injections(point,fail) VALUES(#{quote(point)},true)")
          response = execute("BEGIN ISOLATION LEVEL SERIALIZABLE; SELECT s2_api.purchase('#{TARGET}','plus','failure-#{point}'); COMMIT;", user: 's2_viewer', allow_failure: true)
          assert(response[:status].to_i != 0 && response[:stderr].to_s.include?('synthetic boundary failure'), "Failure injection not reached at #{point}")
          observed = stats
          assert(observed['snapshots'] == 0 && observed['entitlements'] == 0 && observed['debits'] == 0 && observed['balance'] == 4, "Partial effects survived #{point}")
          {point: point, rolled_back: true, postconditions: observed}
        end
        observations
      end
      check('TX15') do
        gate(true); state(buy('plus', 'plus-first'), 'success')
        state(buy('standard', 'standard-included'), 'success')
        state(buy('plus', 'same-plus-again'), 'success')
        assert(stats['debits'] == 1 && stats['snapshots'] == 1, 'Cross-tier fixture access charged/recalculated')
        stats
      end
      check('TX12') do
        observations = 3.times.map do |iteration|
          reset
          admin("INSERT INTO s2_private.wallets(actor,balance) VALUES('#{TARGET}',2); INSERT INTO s2_private.ledger(actor,amount,kind) VALUES('#{TARGET}',2,'grant')")
          retry_offset = @retry_events.length
          results = race(-> { buy('standard', "forward-#{iteration}") },
                         -> { buy('standard', "reverse-#{iteration}", VIEWER, user: 's2_target') })
          assert_race(results); results.each { |r| state(r, 'success') }
          retry_slice = @retry_events.drop(retry_offset)
          assert(retry_slice.none? { |r| r[:error].match?(/40P01|deadlock detected/) }, 'Unexpected protocol deadlock in reverse-pair matrix')
          forward = stats; reverse = stats(VIEWER, TARGET)
          assert(forward['snapshots'] == 1 && reverse['snapshots'] == 1 && forward['debits'] == 1 && reverse['debits'] == 1, 'Reverse-pair protocol race duplicated effects')
          {iteration: iteration + 1, forward: forward, reverse: reverse, serialization_retries: retry_slice.length}
        end
        {boundary: 'No unexpected deadlock in these three measured opposing-direction schedules; not a proof for every possible workload.', observations: observations}
      end
      check('TX13') do
        admin("INSERT INTO s2_fixture.injections(point) VALUES('snapshots'),('ledger')")
        holder = hold_advisory(71400)
        workers = [%w[snapshots ledger], %w[ledger snapshots]].each_with_index.map do |points, index|
          Thread.new do
            execute("\\set VERBOSITY verbose\nBEGIN ISOLATION LEVEL SERIALIZABLE; SELECT point FROM s2_fixture.injections WHERE point=#{quote(points.first)} FOR UPDATE; SELECT pg_advisory_xact_lock(#{71401 + index}); SELECT pg_advisory_xact_lock(71400); SELECT point FROM s2_fixture.injections WHERE point=#{quote(points.last)} FOR UPDATE; COMMIT;", allow_failure: true)
          end
        end
        [71401, 71402].each { |key| wait_for_sql("EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=#{key} AND granted)") }
        holder.value
        results = workers.map(&:value)
        deadlocks = results.select { |r| r[:status].to_i != 0 && r[:stderr].to_s.include?('40P01') }
        assert(deadlocks.length == 1 && results.count { |r| r[:status].to_i.zero? } == 1, 'Controlled fixture lock cycle did not produce exactly one deadlock victim')
        retry_result = admin("SELECT point FROM s2_fixture.injections WHERE point IN ('snapshots','ledger') ORDER BY point FOR UPDATE")
        assert(retry_result[:status].to_i.zero?, 'Ordered fresh fixture transaction did not recover')
        no_purchase_effects
        {fixture_only_deadlock_sqlstate: '40P01', bounded_fresh_ordered_retry: true, ordinary_api_not_modified: true}
      end
      check('AC02') do
        restriction_after_preflight(71002, "SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false)")
      end
      check('AC03') do
        state(buy('standard', 'committed-lost-response'), 'success') # Discard first response as if transport lost it.
        admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false)")
        retry_result = buy('standard', 'committed-lost-response')
        state(retry_result, 'forbidden')
        assert(!retry_result.key?('overall_percentage') && retry_result['receipt'] && stats['debits'] == 1, 'Post-commit retry leaked/charged or lost receipt')
        retry_result
      end
      check('AC10') do
        restriction = Thread.new do
          admin("SELECT s2_fixture.set_access('#{VIEWER}','#{TARGET}',true,false); SELECT pg_advisory_xact_lock(71000); SELECT pg_sleep(2)")
        end
        wait_for_sql("EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=71000 AND granted)")
        purchase = Thread.new { buy('standard', 'revocation-first') }
        wait_for_sql(waiting_role('s2_viewer', 'transactionid'))
        restriction.value; result = purchase.value
        state(result, 'forbidden'); state(read, 'forbidden'); no_purchase_effects
        {revocation_guard_acquired_first: true, response: result, postconditions: stats}
      end
      check('AC04') { restriction_after_preflight(71004, "SELECT s2_fixture.set_subject('#{TARGET}','deleted',false)") }
      check('AC05') { restriction_after_preflight(71005, "SELECT s2_fixture.set_subject('#{TARGET}','suspended',true)") }
      check('AC06') { restriction_after_preflight(71006, "SELECT s2_fixture.set_subject('#{TARGET}','active',false)") }
      revision_consistency_tests
    end

    def additional_lifecycle_tests
      check('REC07') do
        gate(true); state(buy('plus', 'committed-before-projection-failure'), 'success')
        admin("UPDATE s2_private.disclosure_bindings SET projection='{" + '"state":"unavailable"' + "}'::jsonb WHERE viewer='#{VIEWER}' AND target='#{TARGET}'")
        state(read('plus'), 'unavailable')
        recovered = buy('plus', 'retry-committed-projection-failure'); state(recovered, 'unavailable')
        assert(stats['debits'] == 1 && stats['entitlements'] == 1 && stats['snapshots'] == 1, 'Projection failure charged again or fabricated another result')
        {typed_result: recovered, postconditions: stats}
      end
      check('REC10') do
        admin("INSERT INTO s2_private.entitlements(viewer,target,tier) VALUES('#{VIEWER}','#{TARGET}','standard'); DELETE FROM s2_private.input_heads WHERE subject_id='#{TARGET}' AND kind='answers'")
        result = api('legacy_transition', TARGET, 'irreproducible-legacy')
        state(result, 'unavailable')
        assert(!result.key?('overall_percentage') && stats['snapshots'] == 0 && stats['debits'] == 0 && stats['entitlements'] == 1, 'Missing legacy data invented a score, lost entitlement or charged')
        result
      end
      check('PR06') do
        outcomes = %w[standard_first plus_first].map do |order|
          reset; gate(true)
          if order == 'standard_first'
            state(buy('standard', 'order-standard'), 'success'); state(buy('plus', 'order-plus'), 'success')
          else
            state(buy('plus', 'order-plus'), 'success'); state(buy('standard', 'order-standard'), 'success')
          end
          standard = read; plus = read('plus')
          state(standard, 'success'); state(plus, 'success')
          assert(stats['snapshots'] == 1, 'Purchase order generated a second calculation')
          {order: order, percentage: standard['overall_percentage'], projection: plus['projection'], snapshots: stats['snapshots']}
        end
        assert(outcomes.first[:percentage] == outcomes.last[:percentage] && outcomes.first[:projection] == outcomes.last[:projection], 'Standard/Plus ordering changed disclosure basis')
        outcomes
      end
      check('PR07') do
        outcomes = %w[journey_first purchase_first].map do |order|
          reset
          if order == 'journey_first'
            state(api('reveal_journey', TARGET, 'order-journey'), 'success'); state(buy, 'success')
          else
            state(buy, 'success'); state(api('reveal_journey', TARGET, 'order-journey'), 'success')
          end
          journey = read('journey'); standard = read
          state(journey, 'success'); state(standard, 'success')
          assert(journey['overall_percentage'] == standard['overall_percentage'] && stats['snapshots'] == 1 && stats['debits'] == 1, 'Journey/paid order changed result or charged Journey')
          {order: order, percentage: standard['overall_percentage'], postconditions: stats}
        end
        assert(outcomes.first[:percentage] == outcomes.last[:percentage], 'Journey-first and purchase-first basis differed')
        outcomes
      end
      check('PR11') do
        gate(true); category = @export['manifest']['categories'].first
        admin("UPDATE s2_private.configuration SET allowed_categories=ARRAY[#{quote(category)}],min_categories=1 WHERE id=1")
        state(buy('plus'), 'success'); result = read('plus'); state(result, 'success')
        categories = result['projection']['categories']
        assert(categories.map { |c| c['category'] } == @export['manifest']['categories'], 'Unavailable categories omitted or reordered')
        assert(categories.all? { |c| c.keys.sort == %w[band category] }, 'Category availability disclosed reasons/private metadata')
        assert(categories.count { |c| c['band'] == 'unavailable' } == 11, 'Neutral unavailable projection not retained')
        result['projection']
      end
      check('VAL05') do
        preferences = payload(VIEWER, 'preferences')
        preferences['controls'].each { |c| c['hards'] = []; c['lights'].each { |l| l['value'] = 'red' } }
        preferences['chapter2'].each do |block|
          if block['key'] == 'sect'
            chapter2_fields(preferences, 'sect').find { |f| f['key'] == 'matrix' }['value'].each { |l| l['value'] = 'red' }
          elsif block['key'] == 'revert'
            set_field(block['fields'], 'flexibility', 'red')
          else
            set_field(block['fields'], 'preferred', []); set_field(block['fields'], 'skipped', true)
          end
        end
        assert(capture(VIEWER, 'preferences', preferences)[:status].to_i.zero?, 'Valid zero Plus fixture rejected')
        gate(true); result = buy('plus'); state(result, 'success')
        assert(result['overall_percentage'] == 0, 'Zero treated as missing Plus result')
        deen = result['projection']['categories'].find { |c| c['category'] == 'deen_practice' }
        assert(deen['band'] == 'synthetic_band' && stats['debits'] == 1, 'Valid zero category incorrectly unavailable or charged wrong amount')
        {zero_result_available: true, symbolic_band_only: true, postconditions: stats}
      end
      check('LIFE06') do
        state(buy, 'success')
        admin("SELECT s2_fixture.set_subject('#{TARGET}','deleted',false); INSERT INTO s2_private.subjects(subject_id,sex) VALUES('synthetic-reregistered-target','female')")
        result = read('standard', 'synthetic-reregistered-target')
        state(result, 'forbidden')
        transferred = scalar("SELECT to_jsonb(count(*)) FROM s2_private.entitlements WHERE viewer='#{VIEWER}' AND target='synthetic-reregistered-target'")
        assert(transferred == 0 && stats['entitlements'] == 1 && stats['debits'] == 1, 'Synthetic new subject inherited old entitlement')
        {fixture_contract_only: true, implicit_transfer: false, production_identity_policy_decided: false}
      end
    end

    def revision_consistency_tests
      [['REV01', VIEWER, 'preferences', 'viewer_preferences'], ['REV02', TARGET, 'answers', 'target_answers'], ['REV03', VIEWER, 'preferences', 'viewer_preferences']].each_with_index do |(id, subject, kind, input_key), index|
        check(id) do
          changed = payload(subject, kind)
          if id == 'REV01'
            changed['controls'].each { |c| c['lights'].each { |l| l['value'] = 'red' } }
          elsif id == 'REV02'
            definition = @export['manifest']['answers'].find { |q| q['eligible'] && q['selection']=='single' && q['variant'].nil? && q['parent_key'].nil? && q['question_id']!='ch3_q3' && q['options'].length>1 }
            changed['answers'].find { |a| a['key']==definition['key'] }['value'] = definition['options'][1]
          else
            definition = @export['manifest']['preferences'].find { |q| q['hard_supported'] && q['target_pool'].include?('female') }
            changed['controls'].find { |c| c['id']==definition['id'] }['hards'] = [definition['options'].first]
          end
          original_revision = scalar("SELECT to_jsonb(revision_id) FROM s2_private.input_heads WHERE subject_id=#{quote(subject)} AND kind=#{quote(kind)}")
          key = 71501 + index
          admin("INSERT INTO s2_fixture.injections(point,advisory_key) VALUES('snapshots',#{key})")
          holder = hold_advisory(key)
          purchase = Thread.new { buy('standard', "capture-race-#{id}") }
          wait_for_sql(waiting_role('s2_viewer'))
          writer = Thread.new { admin("SELECT s2_private.capture(#{quote(subject)},#{quote(kind)},#{quote(JSON.generate(changed))}::jsonb)") }
          wait_for_sql(waiting_role('postgres', 'transactionid'))
          holder.value; result = purchase.value; writer.value
          state(result, 'success')
          snapshot_revisions = scalar("SELECT input_revision_ids FROM s2_private.snapshots WHERE snapshot_id=#{stats['current_snapshot_id']}")
          current_revision = scalar("SELECT to_jsonb(revision_id) FROM s2_private.input_heads WHERE subject_id=#{quote(subject)} AND kind=#{quote(kind)}")
          assert(snapshot_revisions[input_key].to_i == original_revision.to_i && current_revision != original_revision, 'Concurrent capture mixed/replaced the initial coherent revision')
          assert(read['overall_percentage'] == result['overall_percentage'] && stats['snapshots'] == 1, 'Post-commit capture refreshed saved result')
          {capture_attempt_blocked_during_precommit: true, captured_revision: original_revision, later_head: current_revision, snapshot_revisions: snapshot_revisions}
        end
      end
      check('REV04') do
        key = 71504
        admin("INSERT INTO s2_fixture.injections(point,advisory_key) VALUES('snapshots',#{key})")
        holder = hold_advisory(key)
        purchase = Thread.new { buy('standard', 'configuration-race') }
        wait_for_sql(waiting_role('s2_viewer'))
        writer = Thread.new { admin("UPDATE s2_private.configuration SET manifest_version='unsupported-synthetic-version',revision=revision+1 WHERE id=1") }
        wait_for_sql(waiting_role('postgres', 'transactionid'))
        holder.value; result = purchase.value; writer.value
        state(result, 'success'); state(read, 'success')
        versions = scalar("SELECT versions FROM s2_private.snapshots WHERE snapshot_id=#{stats['current_snapshot_id']}")
        assert(versions['manifest'] == @export['manifest']['version'], 'Calculation mixed manifest versions')
        rejected = buy('standard', 'new-config-target', TARGET2); state(rejected, 'system_failure')
        no_purchase_effects(TARGET2)
        {configuration_writer_waited_for_commit: true, original_versions: versions, later_invalid_configuration_failed_closed: true}
      end
      check('REV06') do
        first = payload(VIEWER, 'preferences'); second = Marshal.load(Marshal.dump(first))
        first['controls'].each { |c| c['lights'].each { |l| l['value'] = 'red' } }
        second['controls'].each { |c| c['lights'].each { |l| l['value'] = 'amber' } }
        result = race(-> { admin("SELECT s2_private.capture('#{VIEWER}','preferences',#{quote(JSON.generate(first))}::jsonb)"); {'state'=>'first_capture_committed'} },
                      -> { admin("SELECT s2_private.capture('#{VIEWER}','preferences',#{quote(JSON.generate(second))}::jsonb)"); {'state'=>'second_capture_committed'} })
        assert_race(result)
        head = payload(VIEWER, 'preferences')
        assert(head == first || head == second, 'Concurrent captures created a torn canonical raw payload')
        coherence = scalar("SELECT jsonb_build_object('valid',r.quality='validated' AND r.canonical_payload IS NOT NULL AND r.fingerprint=encode(sha256(convert_to(r.raw_payload::text,'UTF8')),'hex'),'revisions',(SELECT count(*) FROM s2_private.input_revisions WHERE subject_id='#{VIEWER}' AND kind='preferences')) FROM s2_private.input_heads h JOIN s2_private.input_revisions r USING(revision_id) WHERE h.subject_id='#{VIEWER}' AND h.kind='preferences'")
        assert(coherence['valid'] && coherence['revisions'] == 3, 'Concurrent revisions lost provenance or history entries')
        {responses: result, coherent_head: coherence}
      end
    end

    def inference_probe
      check('OBS01') do
        definition = @export['manifest']['answers'].find do |q|
          q['eligible'] && q['selection'] == 'single' && q['variant'].nil? && q['parent_key'].nil? &&
            !%w[ch3_q3 ch3_q24 ch3_q26 ch3_q39].include?(q['question_id']) && q['options'].length >= 2
        end
        raise 'No eligible unconditional two-option synthetic question' unless definition
        options = definition['options'].first(2)
        observed = options.each_with_index.map do |selected, world|
          reset if world.positive? # Distinct privileged synthetic worlds, not client refresh.
          prefs = payload(VIEWER, 'preferences')
          prefs['controls'].each do |c|
            c['hards'] = []
            c['lights'].each { |l| l['value'] = 'green' }
          end
          control = prefs['controls'].find { |c| c['id'] == "pref:#{definition['key']}" }
          control['lights'].find { |l| l['option'] == options.first }['value'] = 'red'
          answers = payload(TARGET, 'answers')
          answers['answers'].find { |a| a['key'] == definition['key'] }['value'] = selected
          assert(capture(VIEWER, 'preferences', prefs)[:status].to_i.zero?, 'Synthetic probing preference invalid')
          assert(capture(TARGET, 'answers', answers)[:status].to_i.zero?, 'Synthetic alternative world invalid')
          result = buy('standard', 'first-unlock-in-synthetic-world')
          state(result, 'success')
          {world: world + 1, selected_option: selected, overall_percentage: result['overall_percentage']}
        end
        assert(observed.map { |v| v[:overall_percentage] }.uniq.length == 2, 'Probe did not distinguish two possible worlds')
        {measurement: 'Exact Standard percentage distinguishes the tested two complete valid synthetic worlds.',
         residual_risk: 'Under the stated prior-knowledge assumptions, the first overall result identifies the differing target option.',
         assumptions: 'Attacker knows all other contributing answers and knows the target chose one of these two options; target applicability and denominator are unchanged.',
         question: definition['key'], observations: observed,
         privacy_safe: false, production_risk_acceptance: false,
         boundary: 'Two administrator-reset isolated worlds; no ordinary-user recalculation or refresh API was used.'}
      end
      outcome = @results.find { |r| r[:id] == 'OBS01' }
      outcome[:status] = 'measured' if outcome && outcome[:status] == 'passed'
    end
  end
end
