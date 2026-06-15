# rubocop-hash_inspect

A RuboCop extension gem that flags Ruby code relying on the **legacy (Ruby <= 3.3)
`Hash#inspect` output format**. Ruby 3.4 changed `Hash#inspect` from `{:x=>1}` to
`{x: 1}`, breaking tests that hardcode the old rocket-syntax form. This cop catches
those literals statically during `pdk validate` so Puppet module authors can fix them
before upgrading to Puppet 9 (Ruby 4).

> **TODO (DOC-01, Phase 3):** Replace stub content with full documentation.

## Why This Matters — Ruby 3.4 Hash#inspect Change

Ruby 3.4 (December 2024) changed the output of `Hash#inspect`:

- **Ruby <= 3.3 (Puppet 8):** `{:x=>1, "baz"=>3}`
- **Ruby >= 3.4 (Puppet 9 / Ruby 4):** `{x: 1, "baz" => 3}`

Code that hardcodes the old format in test assertions silently breaks on Puppet 9.
This cop detects the legacy rocket-syntax format inside string and regexp literals.

## Installation

> **TODO (DOC-01):** Add RubyGems install instructions after gem is published.

Add to your `.rubocop.yml` (preferred — requires RuboCop >= 1.72):

```yaml
plugins:
  - rubocop-hash_inspect
```

Or using the legacy `require:` directive (compatible with all RuboCop versions):

```yaml
require:
  - rubocop-hash_inspect
```

## Usage

> **TODO (DOC-01):** Document `HashInspect/LegacyHashInspectFormat` cop configuration,
> examples of flagged and clean code, and configuration options.

Once loaded, the cop `HashInspect/LegacyHashInspectFormat` runs automatically as part
of `rubocop` (or `pdk validate` when wired via `pdk-templates`).

### Cop: `HashInspect/LegacyHashInspectFormat`

> **TODO (DOC-01):** Full cop documentation including offense examples and remediation
> guidance.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`bundle exec rake` to run the spec suite and self-lint together.

```bash
bin/setup
bundle exec rake          # spec + self-lint (default task)
bundle exec rake spec     # specs only
bundle exec rake rubocop  # self-lint only
```

To generate a new cop skeleton:

```bash
bundle exec rake 'new_cop[HashInspect/CopName]'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/puppetlabs/rubocop-hash_inspect.

## License

This gem is available as open source under the terms of the [Apache License 2.0](LICENSE).
