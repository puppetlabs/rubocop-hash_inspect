# frozen_string_literal: true

RSpec.describe RuboCop::Cop::HashInspect::LegacyHashInspectFormat, :config do
  # --- Positive cases: str literals ---

  context 'with a plain str literal matching the legacy signature' do
    it 'registers an offense for the {:a=>1} form with exact message (COP-05)' do
      expect_offense(<<~RUBY)
        eq("{:a=>1}")
           ^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for a multi-key legacy hash string' do
      expect_offense(<<~RUBY)
        expect(x).to eq("{:a=>1, :b=>2}")
                        ^^^^^^^^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for a quoted-symbol key form (D-02)' do
      expect_offense(<<~RUBY)
        eq('{:"foo-bar"=>1}')
           ^^^^^^^^^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for an authentic rspec-puppet catalog attribute pattern (D-21)' do
      # Real pattern: rspec-puppet test comparing a catalog resource hash attribute
      # as seen in Puppet module specs like puppetlabs-stdlib and puppetlabs-concat.
      # Single-quoted heredoc ensures the Ruby string inside the test source
      # (including the quoted hash key) is not interpolated by the outer heredoc.
      expect_offense(<<~'RUBY')
        is_expected.to contain_file('/etc/foo').with_content("{:name=>\"bar\"}")
                                                             ^^^^^^^^^^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end
  end

  # --- Positive cases: dstr (interpolated string) ---

  context 'with a dstr (interpolated string) matching the legacy signature (D-05)' do
    it 'registers an offense when the brace and key appear in the static segment' do
      # Single-quoted heredoc prevents Ruby from interpolating #{...} before RuboCop parses it
      expect_offense(<<~'RUBY')
        eq("{:a=>#{val}}")
           ^^^^^^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end
  end

  # --- Positive cases: regexp ---

  context 'with a regexp literal matching the legacy signature (D-06)' do
    it 'registers an offense for a %r{} regexp with escaped-brace legacy form' do
      expect_offense(<<~RUBY)
        expect(x).to match(%r{\\{:a=>1\\}})
                           ^^^^^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end

    it 'registers an offense for an unescaped-brace regexp' do
      expect_offense(<<~RUBY)
        expect(x).to match(/{:a=>1}/)
                           ^^^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
      RUBY

      expect_no_corrections
    end
  end

  # --- Positive cases: heredoc (D-08) ---

  context 'with a heredoc string containing the legacy signature (D-08)' do
    it 'registers an offense for a heredoc body containing the legacy signature' do # rubocop:disable RSpec/ExampleLength
      expect_offense(<<~RUBY)
        x = <<~TEXT
            ^^^^^^^ Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 / Puppet 9. Update it to the new format.
          {:a=>1}
        TEXT
      RUBY

      expect_no_corrections
    end
  end

  # --- Negative cases (D-22): must NOT register any offense ---

  context 'with new-format (Ruby 3.4+) hash output' do
    it 'does not register for symbol key new format' do
      expect_no_offenses(<<~RUBY)
        eq("{a: 1}")
      RUBY
    end

    it 'does not register for string key new format with spaces' do
      expect_no_offenses(<<~RUBY)
        eq('{"baz" => 3}')
      RUBY
    end
  end

  context 'with spaced rocket — not legacy inspect output' do
    it 'does not register for {:a => 1} with spaces around =>' do
      expect_no_offenses(<<~RUBY)
        eq("{:a => 1}")
      RUBY
    end
  end

  context 'with string-keyed no-space rocket (excluded from v1, D-03)' do
    it 'does not register for {"baz"=>3} (string key without colon prefix)' do
      expect_no_offenses(<<~RUBY)
        eq('{"baz"=>3}')
      RUBY
    end
  end

  context 'with bare :sym=> without an enclosing brace' do
    it 'does not register for bare :a=>1 string lacking an opening brace' do
      expect_no_offenses(<<~RUBY)
        eq(":a=>1")
      RUBY
    end
  end

  context 'with real Ruby hash literals in source (not strings — D-10)' do
    it 'does not register for a hash literal with symbol-colon syntax' do
      expect_no_offenses(<<~RUBY)
        { a: 1 }
      RUBY
    end

    it 'does not register for a hash literal with rocket syntax' do
      expect_no_offenses(<<~RUBY)
        { :a => 1 }
      RUBY
    end
  end

  context 'with empty or unrelated strings' do
    it 'does not register for an empty string' do
      expect_no_offenses(<<~RUBY)
        eq("")
      RUBY
    end

    it 'does not register for a partial signature string lacking an opening brace' do
      expect_no_offenses(<<~RUBY)
        eq(":a=>1 is the format")
      RUBY
    end
  end

  context 'with a comment containing the legacy signature (D-09)' do
    it 'does not register for a comment line containing {:a=>1}' do
      # Comments are not AST string nodes, so the cop never sees them
      expect_no_offenses(<<~RUBY)
        # expected {:a=>1}
        eq("{a: 1}")
      RUBY
    end
  end

  # --- Regression specs for interpolation-boundary handling (WR-01 / WR-02) ---

  context 'with a dynamic prefix before the rocket signature (WR-01)' do
    # WR-01 regression guard: before the sentinel fix, on_dstr joined segments
    # "{" + ":role=>admin}" = "{:role=>admin}" which matched LEGACY_SIGNATURE,
    # producing a false offense. The runtime value is e.g. "{user:role=>admin}"
    # which is NOT a legacy Hash#inspect string. See 02-VERIFICATION.md WR-01.
    it 'does not register when a dynamic prefix precedes the rocket pattern' do
      expect_no_offenses(<<~'RUBY')
        eq("{#{prefix}:role=>admin}")
      RUBY
    end
  end

  context 'with an interpolated symbol key — documented heuristic non-detection (WR-02)' do
    # WR-02 documented behavior: a genuine legacy form whose KEY name is dynamic,
    # e.g. "{:#{key}=>1}", is intentionally not detected. The key name is unknown
    # at static-analysis time, and the interpolation-gap sentinel (WR-01 fix)
    # also prevents fabricating a signature across the #{} boundary.
    # This is a known, intentional heuristic limitation — not an accidental gap.
    # See 02-VERIFICATION.md WR-02 and the cop class docstring.
    it 'does not register for an interpolated symbol key (intentional non-detection, WR-02)' do
      expect_no_offenses(<<~'RUBY')
        eq("{:#{key}=>1}")
      RUBY
    end
  end

  context 'with new-format value containing an arrow (IN-03)' do
    it 'does not register for new-format hash output with arrow in value' do
      expect_no_offenses(<<~RUBY)
        eq("{a: x => y}")
      RUBY
    end
  end
end
