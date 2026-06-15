<!-- GSD:project-start source:PROJECT.md -->
## Project

**rubocop-hash_inspect**

A RuboCop extension gem that provides a single, conservative cop flagging Ruby code that relies on the **legacy (Ruby ≤ 3.3) `Hash#inspect` output format**. Ruby 3.4 (Dec 2024) changed `Hash#inspect` from `{:x=>1, "baz"=>3}` to `{x: 1, "baz" => 3}` ([Ruby Bug #20433](https://bugs.ruby-lang.org/issues/20433)), and that format carries into Puppet 9's Ruby 4 runtime. Code that hardcodes the old format — most commonly test contracts comparing against literal strings like `eq("{:a=>1}")` — breaks silently on Puppet 9. The cop catches this statically during `pdk validate` so Puppet module authors can fix it before upgrading.

This gem is the deliverable for [CAT-2635](https://perforce.atlassian.net/browse/CAT-2635) (parent epic CAT-2630 — PDK | Puppet 9 Compatibility Testing).

**Core Value:** `pdk validate` flags reliance on legacy `Hash#inspect` output with actionable, low-false-positive output, so module authors fix it before Puppet 9 / Ruby 4 breaks them — with zero behavior change for Puppet 8 (Ruby 3.2) validation.

### Constraints

- **Tech stack**: Ruby gem, RuboCop extension API (cop + spec + config); RSpec for cop specs using RuboCop's cop test helpers.
- **Compatibility**: Must be additive — no false positives on Puppet 8 / Ruby 3.2 module code; no change to existing `pdk validate` behavior when the cop is disabled.
- **Quality bar**: Heuristic by nature — success criterion relaxed (per CAT-2635 investigation) from "zero false positives" to **no false positives on the curated clean-module baseline**.
- **Dependencies**: Two-repo delivery — the gem itself, plus a `pdk-templates` `.rubocop.yml` PR to wire it into `pdk validate`. The template PR depends on a published/loadable gem.
- **Integration**: Loadable as a RuboCop extension via `require:` in `.rubocop.yml`; configurable like any standard cop.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## Recommended Stack
### Core Technologies
| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| rubocop | `>= 1.72.2` (current: 1.87.0) | Provides `Cop::Base`, AST helpers, plugin machinery, `rspec/support` test harness | The minimum for the new plugin API; current as of May 2026. Pin with `< 2.0` to avoid breaking changes from the upcoming major. |
| rubocop-ast | `>= 1.45.1, < 2.0` (current: 1.49.1) | `NodePattern`, `Node` — the DSL used to match AST subtrees inside cops | Shipped as a separate gem since RuboCop 0.x; always needed explicitly in a gem that uses `def_node_matcher` / `def_node_search`. Lower bound tracks rubocop-performance's own floor. |
| lint_roller | `~> 1.1` (current: 1.1.0) | Provides `LintRoller::Plugin` base class for the modern plugin registration system | Required for the `plugins:` directive in `.rubocop.yml`. A transitive dep of rubocop itself but must be listed explicitly in the gemspec so bundler can resolve it without an implicit assumption. |
| Ruby | `>= 2.7.0` | Runtime | Matches rubocop's own minimum. Puppet 8 ships Ruby 3.2; Puppet 9 ships Ruby 4. Supporting >= 2.7 keeps the gem compatible with both without extra effort. |
### Supporting Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rspec | `~> 3.13` (current: 3.13.2) | Test framework; cop specs use `expect_offense`/`expect_no_offenses` | Always — the rubocop project's own test harness is RSpec-only |
| rake | `~> 13.4` (current: 13.4.2) | `new_cop` Rake task (generator), `spec` task | Always — convention in rubocop extension gems; the extension generator wires both |
| rubocop-internal_affairs | (latest via rubocop plugin) | Lints your own cop code; catches e.g. missing `on_csend` alongside `on_send` | Use in `.rubocop.yml` for the gem's own source quality gate — it's free: just list it under `plugins:` |
### Development Tools
| Tool | Purpose | Notes |
|------|---------|-------|
| `rubocop-extension-generator` | Generates the full gem skeleton from a single command | Run once: `gem install rubocop-extension-generator && rubocop-extension-generator rubocop-hash_inspect`. The generator's output is the canonical skeleton (it is maintained by the RuboCop core team). |
| `bundle gem` | Alternative lower-level scaffold | The extension generator *calls* `bundle gem` internally, then layers on RuboCop-specific files. Don't use `bundle gem` alone — you'll miss `plugin.rb`, `config/default.yml`, and the Rake integration. |
| `bundle exec rake 'new_cop[HashInspect/LegacyHashInspectFormat]'` | Generates the cop skeleton + spec skeleton and wires them into the cops require file and `config/default.yml` | Run after initial generator setup; the only safe way to add a cop because it also injects the `require_relative` entry and a stub `config/default.yml` block. |
## Installation
# Generate the full gem skeleton (run once, outside the repo)
# Inside the generated gem directory
# Generate the cop and its spec skeleton
# rubocop-hash_inspect.gemspec (key lines)
# rubocop-ast is a transitive dep via rubocop, but pin explicitly when using NodePattern
## Plugin Registration Mechanism
### plugin.rb (canonical structure)
# frozen_string_literal: true
### Main entry file (lib/rubocop-hash_inspect.rb)
# frozen_string_literal: true
### User-facing .rubocop.yml (pdk-templates wiring)
## config/default.yml Conventions
# config/default.yml
- `Enabled: true` — ship enabled; the cop is additive and non-blocking
- `Severity: convention` — matches the PROJECT.md requirement ("convention/refactor severity")
- `SafeAutoCorrect: false` — correct; a heuristic cop cannot provide a safe autocorrect since it cannot know what the correct replacement is
- `Safe: true` — the offense detection itself is not side-effectful
- `VersionAdded` — required field; set to `'1.0'` for the initial release
- No `AutoCorrect` key needed when `SafeAutoCorrect: false` and no corrector is defined
## RSpec Testing Setup
### spec/spec_helper.rb
# frozen_string_literal: true
### Cop spec pattern
# spec/rubocop/cop/hash_inspect/legacy_hash_inspect_format_spec.rb
# frozen_string_literal: true
### .rspec
## Gem File Layout
## Alternatives Considered
| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `plugins:` (lint_roller) | `require:` in .rubocop.yml | Internal/private projects where backward-compat with RuboCop < 1.72 is required. For a public PDK gem shipped 2026+, `plugins:` is correct. |
| `Cop::Base` | `Cop::Cop` (deprecated) | Never — `Cop::Cop` is explicitly marked deprecated in RuboCop docs and will be removed in RuboCop 2.0 |
| `rubocop-extension-generator` | Handcrafted skeleton | Only if the generator itself has a bug or the skeleton needs heavy deviation. The generator is maintained by the RuboCop core team and produces the exact structure verified here. |
| `SafeAutoCorrect: false` + no corrector | Provide an autocorrect | This cop is heuristic — it cannot know the correct replacement. Providing an autocorrect would be unsafe and misleading. |
| `Severity: convention` | `warning` or `error` | `error` would block CI on potentially false positives; `warning` is less visible. `convention` matches the PROJECT.md requirement and appears in `pdk validate` output without being blocking. |
## What NOT to Use
| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `RuboCop::Cop::Cop` base class | Explicitly deprecated; removed in RuboCop 2.0; `InheritDeprecatedCopClass` internal affairs cop will flag it | `RuboCop::Cop::Base` |
| `require:` in user-facing .rubocop.yml | Deprecated for published gems since 1.72; emits warnings | `plugins:` |
| `Inject.defaults!` / manual config injection | The pre-plugin era approach; superseded by `Plugin#rules` returning a `LintRoller::Rules` path | `Plugin#rules` returning `config/default.yml` path |
| `bundle gem` alone (without extension generator) | Produces a bare gem skeleton missing `plugin.rb`, `config/default.yml`, and the Rake cop generator task | `rubocop-extension-generator` |
| `AutoCorrect: disabled` in config | Old config key; replaced by `SafeAutoCorrect: false` | `SafeAutoCorrect: false` |
## Version Compatibility
| Package | Version Constraint | Notes |
|---------|-------------------|-------|
| rubocop | `>= 1.72.2, < 2.0` | 1.72 = plugin API introduction; `< 2.0` guards against breaking API changes |
| rubocop-ast | `>= 1.45.1, < 2.0` | Tracks rubocop-performance floor; current 1.49.1 |
| lint_roller | `~> 1.1` | Only version available; `~> 1.1` is the standard constraint used by rubocop-performance and rubocop-rails |
| Ruby | `>= 2.7.0` | Matches rubocop's own floor; Puppet 8 ships 3.2, Puppet 9 ships Ruby 4 — both clear this bar |
| rspec | `~> 3.13` (dev only) | Current stable 3.13.2; rspec 4 beta exists but is not production-ready |
| rake | `~> 13.4` (dev only) | Current 13.4.2 |
- Puppet 8 → Ruby 3.2 (no Hash#inspect change; cop is additive)
- Puppet 9 / Ruby 4 → Ruby 3.4+ format change is present; cop fires correctly
## Sources
- `rubocop/rubocop` (Context7: `/rubocop/rubocop`) — plugin migration guide, development guide, `support.rb` source
- [RuboCop Plugins Docs](https://docs.rubocop.org/rubocop/latest/plugins.html) — verified plugin API, `plugins:` directive, lint_roller dependency
- [RuboCop Plugin Migration Guide](https://docs.rubocop.org/rubocop/latest/plugin_migration_guide.html) — gemspec metadata, `LintRoller::Plugin` class structure
- `rubocop/rubocop-extension-generator` generator source (`generator.rb`) — exact generated file structure, gemspec patches, dependency versions (HIGH confidence: first-party source)
- `rubocop/rubocop-performance` gemspec, `plugin.rb`, `spec_helper.rb` — canonical real-world reference implementation (HIGH confidence)
- [rubocop-ast on RubyGems](https://rubygems.org/gems/rubocop-ast) — current version 1.49.1, released 2026-03-20
- [rubocop 1.87.0 on GitHub](https://github.com/rubocop/rubocop/releases) — current version, released 2026-05-30
- [lint_roller 1.1.0 on RubyGems](https://rubygems.org/gems/lint_roller) — current version
- [rspec 3.13.2 on RubyGems](https://rubygems.org/gems/rspec) — current stable, released 2025-10-21
- [rake 13.4.2 on RubyGems](https://rubygems.org/gems/rake) — current version, released 2026-04-16
- [Evil Martians: Writing custom RuboCop rules in 2026](https://evilmartians.com/chronicles/writing-custom-rubocop-rules-in-2026) — `rubocop-internal_affairs` recommendation, `Cop::Base` vs `Cop::Cop`
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
