# frozen_string_literal: true

# Exact separately-authorised local runtime acquisition. No project env,
# credentials, host mounts, active-context change or existing-profile reuse.
require_relative 'run_stage2'
require 'yaml'

class Stage2Acquisition < Stage2Runner
  PROFILE = 'zyra-compat-stage2'
  COLIMA = '/opt/homebrew/bin/colima'
  PROFILE_PATH = '/Users/shakeelahmad/.colima/zyra-compat-stage2'

  def clean_env
    # Preserve the actual home identity only because Colima requires it;
    # Docker configuration is task-owned and contains no credential helper.
    super.merge('HOME' => '/Users/shakeelahmad', 'USER' => 'shakeelahmad',
                'DOCKER_CONFIG' => File.join(RUNTIME, 'empty-docker-config'))
  end

  def acquire
    started = Time.now.utc.iso8601
    created_here = false
    raise 'Download authority absent' unless @manifest.fetch('runtime_download_authority').start_with?('Founder: do whats next;')
    baseline
    raise 'Profile path already exists; refuse adoption' if File.exist?(PROFILE_PATH) || File.symlink?(PROFILE_PATH)
    raise 'Profile socket already exists' if File.exist?(SOCKET)
    version = must(command([COLIMA, 'version']), 'Colima version')
    raise 'Unreviewed Colima version' unless version.include?('colima version 0.10.3')
    list = must(command([COLIMA, 'list', '--json']), 'profile inventory')
    profiles = list.lines.reject { |line| line.strip.empty? }.map { |line| JSON.parse(line) }
    raise 'Dedicated profile already registered' if profiles.any? { |profile| profile['name'] == PROFILE }
    FileUtils.mkdir_p(File.join(RUNTIME, 'empty-docker-config'), mode: 0o700)
    created_here = true # The exact previously absent target may now be partially created.
    must(command([COLIMA, 'start', PROFILE, '--activate=false', '--template=false',
      '--runtime', 'docker', '--vm-type', 'vz', '--arch', 'aarch64', '--cpus', '2',
      '--memory', '4', '--disk', '20', '--root-disk', '20', '--mount', 'none',
      '--ssh-agent=false', '--ssh-config=false', '--port-forwarder', 'none'], timeout: 600), 'new isolated Colima profile')
    config_path = File.join(PROFILE_PATH, 'colima.yaml')
    raise 'Unexpected profile configuration path' if File.symlink?(config_path)
    config = YAML.safe_load(File.read(config_path), permitted_classes: [], aliases: false)
    raise 'Host mounts enabled' unless (config['mounts'] || []).empty?
    raise 'SSH-agent forwarding enabled' if config['sshAgent'] == true
    raise 'Wrong VM runtime' unless config['runtime'] == 'docker'
    # Colima 0.10.3 generated an incomplete ignore rule on this host.
    # Do not trust --port-forwarder none or proceed to a database from it.
    # A reviewed, task-only Lima correction is required before this guard
    # succeeds; setup/test independently enforce the same runtime guard.
    inspect_vm
    image = @manifest.fetch('image')
    must(docker('pull', '--platform', 'linux/arm64', image), 'official pinned PostgreSQL image')
    image_metadata = JSON.parse(must(docker('image', 'inspect', image), 'pinned image inspect')).first
    raise 'Image architecture drift' unless image_metadata['Architecture'] == 'arm64' && image_metadata['Os'] == 'linux'
    after = must(command([COLIMA, 'list', '--json']), 'post-start profile inventory')
    final_profiles = after.lines.reject { |line| line.strip.empty? }.map { |line| JSON.parse(line) }
    profiles.each do |before|
      current = final_profiles.find { |profile| profile['name'] == before['name'] }
      raise 'Unrelated profile changed' unless current == before
    end
    result = { authority: @manifest['runtime_download_authority'], production_authority: false,
      profile: PROFILE, config: config.slice('runtime', 'mounts', 'sshAgent', 'sshConfig', 'portForwarder'),
      image: image_metadata.slice('Id', 'RepoDigests', 'Architecture', 'Os'),
      existing_profiles_before: profiles, profiles_after: final_profiles,
      protected_source_hashes: baseline, commands: @commands }
    path = File.join(REVIEW, "COMPATIBILITY_UNLOCK_STAGE2_ACQUISITION_#{Time.now.utc.strftime('%Y%m%dT%H%M%S%6NZ')}.json")
    raise 'Evidence collision' if File.exist?(path)
    File.write(path, JSON.pretty_generate(result) + "\n")
    puts JSON.pretty_generate({ evidence: path, profile: PROFILE, image: image, database_created: false })
    journal('acquisition', started)
  rescue StandardError => error
    # Only this invocation's newly-created exact profile may be stopped.
    # Never leave an isolation failure running or adopt an existing profile.
    command([COLIMA, 'stop', PROFILE], timeout: 60) if created_here
    journal('acquisition', started, error)
    raise
  end
end

Stage2Acquisition.new.acquire if $PROGRAM_NAME == __FILE__
