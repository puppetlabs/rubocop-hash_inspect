# frozen_string_literal: true

module RuboCop
  module Cop
    module HashInspect
      # Detects string, interpolated-string, and regexp literals that hardcode
      # the legacy `Hash#inspect` output format from Ruby <= 3.3. Ruby 3.4
      # changed `Hash#inspect` from `{:x=>1}` to `{x: 1}` (Bug #20433). Code
      # that compares against or embeds the old format breaks silently on
      # Ruby 3.4 / Puppet 9.
      #
      # The detection signal is the brace-anchored, no-space symbol-rocket
      # pattern `{:sym=>` (plain or quoted symbol key immediately followed by
      # `=>` with no surrounding spaces). This is the discriminator between the
      # legacy and Ruby 3.4+ formats.
      #
      # Note: string-keyed legacy form `{"baz"=>3}` is explicitly out of scope
      # for v1 (kept to protect the clean-module baseline — FAM-03, v2).
      # Comments and real Ruby hash literal nodes are not scanned by construction.
      #
      # @example
      #   # bad - hardcoded legacy Hash#inspect output
      #   expect(result).to eq("{:a=>1}")
      #   expect(result).to eq("{:\"foo-bar\"=>2}")
      #   expect(result).to match(/\{:a=>1\}/)
      #   expect(result).to eq("{:a=>#{value}}")
      #
      #   # good - use the new format or a dynamic matcher
      #   expect(result).to eq("{a: 1}")
      #   expect(result).to match(/\{a: 1\}/)
      #   expect(result).to include("a:")
      #
      class LegacyHashInspectFormat < Base
        # Offense message (D-12 exact wording).
        MSG = 'Legacy `Hash#inspect` format (`{:sym=>...}`). Ruby 3.4+ renders ' \
              'hashes as `{sym: ...}`, so this hardcoded value breaks on Ruby 3.4 ' \
              '/ Puppet 9. Update it to the new format.'

        # Detection regex (D-11): brace-anchored, no-space symbol-rocket.
        # Matches `{` followed by any non-`}` content, then a symbol key
        # (plain `\w+` or double-quoted `"[^"]*"`) immediately followed by
        # `=>` with no surrounding spaces. This discriminates against:
        #   - Ruby 3.4+ new format (uses `: ` not `=>`)
        #   - spaced rockets (`{:a => 1}` — has spaces around `=>`)
        #   - string-keyed form (`{"baz"=>3}` — no leading `:`)
        #   - bare `:a=>1` without an enclosing brace
        # Uses negated character class and non-overlapping alternation only —
        # no nested quantifiers — ensuring linear-time matching (T-02-01).
        LEGACY_SIGNATURE = /\{[^}]*:(?:\w+|"[^"]*")=>/.freeze

        # Called on every `str` (plain string literal) node. Reads the node's
        # unescaped String value (never `node.source` — D-10) and fires an
        # offense on the outer node when it matches LEGACY_SIGNATURE (D-07).
        def on_str(node)
          value = node.children.first
          add_offense(node) if value.is_a?(String) && LEGACY_SIGNATURE.match?(value)
        end

        # Called on every `dstr` (interpolated string) node. Concatenates only
        # the literal `str_type?` child segments (gaps from `#{…}` interpolation
        # are left empty), then fires on the outer dstr node on match (D-05, D-07).
        # E.g. `"{:a=>#{v}}"` produces static text `{:a=>` which matches.
        def on_dstr(node)
          static_text = node.children
                            .select(&:str_type?)
                            .map { |child| child.children.first }
                            .join
          add_offense(node) if LEGACY_SIGNATURE.match?(static_text)
        end

        # Called on every `regexp` node. Concatenates `str_type?` children as
        # above, then normalizes escaped braces (`\{`->`{`, `\}`->`}`) so that
        # `/\{:a=>1\}/` matches the same brace-anchored signature as the string
        # form (D-06, D-07).
        def on_regexp(node)
          static_text = node.children
                            .select(&:str_type?)
                            .map { |child| child.children.first }
                            .join
          unescaped = static_text.gsub('\\{', '{').gsub('\\}', '}')
          add_offense(node) if LEGACY_SIGNATURE.match?(unescaped)
        end
      end
    end
  end
end
