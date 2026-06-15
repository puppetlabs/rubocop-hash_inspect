# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module HashInspect
    # A plugin that integrates rubocop-hash_inspect with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-hash_inspect',
          version: VERSION,
          homepage: 'https://github.com/puppetlabs/rubocop-hash_inspect',
          description: 'A RuboCop extension that flags reliance on legacy Hash#inspect output format.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
