# frozen_string_literal: true

RSpec.describe RuboCop::HashInspect::Plugin do
  subject(:plugin) { described_class.new({}) }

  let(:rubocop_context) do
    LintRoller::Context.new(
      runner: :rubocop,
      runner_version: RuboCop::Version::STRING,
      engine: :rubocop,
      engine_version: RuboCop::Version::STRING,
      target_ruby_version: 2.7
    )
  end

  it 'loads without error' do
    expect { require 'rubocop-hash_inspect' }.not_to raise_error
  end

  it 'is a LintRoller::Plugin' do
    expect(plugin).to be_a(LintRoller::Plugin)
  end

  it 'reports the correct name' do
    expect(plugin.about.name).to eq('rubocop-hash_inspect')
  end

  it 'supports the rubocop engine' do
    expect(plugin.supported?(rubocop_context)).to be(true)
  end

  it 'returns a LintRoller::Rules' do
    expect(plugin.rules(nil)).to be_a(LintRoller::Rules)
  end

  it 'returns a rules path ending with config/default.yml' do
    expect(plugin.rules(nil).value.to_s).to end_with('config/default.yml')
  end

  it 'returns a rules path to an existing file' do
    expect(File.exist?(plugin.rules(nil).value.to_s)).to be(true)
  end
end
