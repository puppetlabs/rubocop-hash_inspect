# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-06-17

### Added

- `HashInspect/LegacyHashInspectFormat` cop: flags string, interpolated-string, and
  regexp literals containing the legacy `Hash#inspect` output format
  (`{:sym=>val}`, Ruby <= 3.3). Ruby 3.4 changed `Hash#inspect` to `{sym: val}`;
  hardcoded strings using the old format break on Ruby 3.4 / Puppet 9
  ([Ruby Bug #20433](https://bugs.ruby-lang.org/issues/20433)).

## [0.1.0] - 2026-06-15

### Added

- Gem skeleton with plugin registration via `LintRoller::Plugin`
- Support for loading via both `plugins:` (RuboCop >= 1.72) and `require:` directives
- `config/default.yml` scaffold (zero cops — `LegacyHashInspectFormat` cop lands in 0.2.0)
