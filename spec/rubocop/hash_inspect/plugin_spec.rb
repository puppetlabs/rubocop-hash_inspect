# frozen_string_literal: true

RSpec.describe RuboCop::HashInspect::Plugin do
  it 'loads without error' do
    expect { require 'rubocop-hash_inspect' }.not_to raise_error
  end

  it 'registers a valid LintRoller::Plugin' do
    plugin = described_class.new({})
    expect(plugin).to be_a(LintRoller::Plugin)
    expect(plugin.about.name).to eq('rubocop-hash_inspect')
  end

  it 'supports the rubocop engine' do
    plugin = described_class.new({})
    context = LintRoller::Context.new(
      runner: :rubocop,
      runner_version: RuboCop::Version::STRING,
      engine: :rubocop,
      engine_version: RuboCop::Version::STRING,
      target_ruby_version: 2.7
    )
    expect(plugin.supported?(context)).to be(true)
  end

  it 'returns a valid rules path pointing to config/default.yml' do
    plugin = described_class.new({})
    rules = plugin.rules(nil)
    expect(rules).to be_a(LintRoller::Rules)
    expect(rules.value.to_s).to end_with('config/default.yml')
    expect(File.exist?(rules.value.to_s)).to be(true)
  end
end
