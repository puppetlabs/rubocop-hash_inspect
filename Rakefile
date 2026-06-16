# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]

desc 'Generate a new cop with a template'
task :new_cop, [:cop] do |_task, args|
  require 'rubocop'

  cop_name = args.fetch(:cop) do
    warn 'usage: bundle exec rake new_cop[Department/Name]'
    exit!
  end

  generator = RuboCop::Cop::Generator.new(cop_name)

  generator.write_source
  generator.write_spec
  generator.inject_require(root_file_path: 'lib/rubocop/cop/hash_inspect_cops.rb')
  generator.inject_config(config_file_path: 'config/default.yml')

  puts generator.todo
end

desc 'Run cop against clean-module baseline (requires network; CI-only)'
task :baseline do
  require 'open3'
  require 'tmpdir'

  repos = %w[
    https://github.com/puppetlabs/puppetlabs-stdlib.git
    https://github.com/puppetlabs/puppetlabs-concat.git
  ]

  Dir.mktmpdir('rubocop-hash_inspect-baseline') do |tmpdir|
    repos.each do |repo|
      name = File.basename(repo, '.git')
      clone_dir = File.join(tmpdir, name)

      puts "Cloning #{repo}..."
      system("git clone --depth=1 --quiet #{repo} #{clone_dir}") ||
        abort("Failed to clone #{repo}")

      config_path = File.join(clone_dir, '.rubocop_baseline.yml')
      File.write(config_path, <<~YAML)
        plugins:
          - rubocop-hash_inspect
        AllCops:
          DisabledByDefault: true
          NewCops: enable
        HashInspect/LegacyHashInspectFormat:
          Enabled: true
      YAML

      puts "Running cop on #{name}..."
      cmd = "bundle exec rubocop --only HashInspect/LegacyHashInspectFormat " \
            "--config #{config_path} --format progress #{clone_dir}"
      stdout, stderr, status = Open3.capture3(cmd)

      unless status.success?
        puts stdout
        puts stderr
        abort "BASELINE FAILURE: #{name} produced offenses. " \
              'Review above output for false positives or genuine upstream legacy-format literals.'
      end

      puts "#{name}: CLEAN (zero offenses)"
    end
  end
end
