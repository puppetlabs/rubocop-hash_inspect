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
      # Known heuristic limitation (WR-02): an interpolated string whose symbol
      # KEY name is dynamic, e.g. `"{:#{key}=>1}"`, is not detected. The key
      # name is unknown at static-analysis time, and the interpolation-gap
      # sentinel (WR-01 fix) also prevents fabricating a signature across the
      # `#{}` boundary. This is an intentional, documented non-detection; it is
      # not an accidental gap.
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
        # Skips `str` nodes that are literal segments inside a `dstr` or
        # `regexp` — those are handled by `on_dstr`/`on_regexp` which report
        # on the outer node (D-07). Prevents duplicate offenses.
        def on_str(node)
          return if node.parent&.type?(:dstr, :regexp)

          value = node.children.first
          add_offense(node) if value.is_a?(String) && LEGACY_SIGNATURE.match?(value)
        end

        # Called on every `dstr` (interpolated string) node. Maps over ALL
        # children: literal `str_type?` segments contribute their text value;
        # each interpolation (`begin`/`send`/etc.) node is replaced by the
        # sentinel `' } '` (space + closing-brace + space). This prevents the
        # regex from matching a signature fabricated across a `#{}` boundary
        # (WR-01 fix): the `}` in the sentinel terminates `[^}]*`, and the
        # spaces break any `:sym=>`/`\w+` run.
        # E.g. `"{:a=>#{v}}"` produces `"{:a=> } "` which still matches because
        # the full `{:a=>` is in the static segment before the sentinel.
        # E.g. `"{#{prefix}:role=>admin}"` produces `"{ }  :role=>admin}"` which
        # does NOT match because `{` and `:role=>` are separated by the sentinel.
        def on_dstr(node)
          static_text = static_text_with_sentinels(node)
          add_offense(node) if LEGACY_SIGNATURE.match?(static_text)
        end

        # Called on every `regexp` node. Applies the same sentinel-aware
        # concatenation as `on_dstr` via `static_text_with_sentinels`, then
        # normalizes escaped braces (`\{`->`{`, `\}`->`}`) so that
        # `/\{:a=>1\}/` matches the same brace-anchored signature as the string
        # form (D-06, D-07). The gsub unescape step runs on the joined text
        # after sentinel insertion, exactly preserving WR-03's load-bearing
        # behaviour for `%r{\{...\}}` patterns.
        def on_regexp(node)
          static_text = static_text_with_sentinels(node)
          unescaped = static_text.gsub('\\{', '{').gsub('\\}', '}')
          add_offense(node) if LEGACY_SIGNATURE.match?(unescaped)
        end

        private

        # Returns a string formed by joining each child of `node`: literal
        # `str_type?` children contribute their text; all other children
        # (interpolations) contribute the sentinel `' } '`. The `}` in the
        # sentinel terminates the regex's `[^}]*` run so a LEGACY_SIGNATURE
        # cannot be fabricated across an interpolation boundary (WR-01).
        def static_text_with_sentinels(node)
          node.children.map do |child|
            child.str_type? ? child.children.first : ' } '
          end.join
        end
      end
    end
  end
end
