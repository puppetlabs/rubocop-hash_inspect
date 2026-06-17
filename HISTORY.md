# History

This file contains the pre-automation history for `rubocop-hash_inspect`.
Going forward, `CHANGELOG.md` is managed by `gh-changelog` from labeled merged PRs.

## [0.2.0] - 2026-06-17

### Added

- `HashInspect/LegacyHashInspectFormat` cop: flags string, interpolated-string, and
  regexp literals containing the legacy `Hash#inspect` output format
  (`{:sym=>val}`, Ruby <= 3.3).

## [0.1.0] - 2026-06-15

### Added

- Gem skeleton with plugin registration via `LintRoller::Plugin`.
- Support for loading via both `plugins:` (RuboCop >= 1.72) and `require:` directives.
- `config/default.yml` scaffold.
