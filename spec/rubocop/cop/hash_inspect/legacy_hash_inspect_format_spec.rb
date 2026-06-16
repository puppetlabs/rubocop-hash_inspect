# frozen_string_literal: true

RSpec.describe RuboCop::Cop::HashInspect::LegacyHashInspectFormat, :config do
  # TODO: Placeholder — full spec suite added in plan 02-02.
  it 'registers an offense for a legacy Hash#inspect string literal' do
    expect_offense(<<~RUBY)
      "{:a=>1}"
      ^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
    RUBY

    expect_no_corrections
  end

  it 'does not register an offense for a new-format hash string' do
    expect_no_offenses(<<~RUBY)
      "{a: 1}"
    RUBY
  end
end
