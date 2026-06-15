# rubocop-hash_inspect

## What This Is

A RuboCop extension gem that provides a single, conservative cop flagging Ruby code that relies on the **legacy (Ruby ≤ 3.3) `Hash#inspect` output format**. Ruby 3.4 (Dec 2024) changed `Hash#inspect` from `{:x=>1, "baz"=>3}` to `{x: 1, "baz" => 3}` ([Ruby Bug #20433](https://bugs.ruby-lang.org/issues/20433)), and that format carries into Puppet 9's Ruby 4 runtime. Code that hardcodes the old format — most commonly test contracts comparing against literal strings like `eq("{:a=>1}")` — breaks silently on Puppet 9. The cop catches this statically during `pdk validate` so Puppet module authors can fix it before upgrading.

This gem is the deliverable for [CAT-2635](https://perforce.atlassian.net/browse/CAT-2635) (parent epic CAT-2630 — PDK | Puppet 9 Compatibility Testing).

## Core Value

`pdk validate` flags reliance on legacy `Hash#inspect` output with actionable, low-false-positive output, so module authors fix it before Puppet 9 / Ruby 4 breaks them — with zero behavior change for Puppet 8 (Ruby 3.2) validation.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Custom RuboCop cop detects string/regexp literals matching the legacy `Hash#inspect` output signature (the `:sym=>value` rocket form, e.g. `"{:a=>1}"`)
- [ ] Cop emits actionable offenses (file, line, message, suggested-fix guidance where possible)
- [ ] Cop is configurable via standard RuboCop config (enable/disable, severity); ships enabled at **convention/refactor** severity
- [ ] Cop produces no false positives against the curated clean-module baseline
- [ ] Gem packaged as a standard RuboCop extension (loadable via `require:` in `.rubocop.yml`)
- [ ] `pdk-templates` `.rubocop.yml` wiring delivered so the cop runs as part of `pdk validate` (separate PR against pdk-templates)
- [ ] PDK reference docs updated with cop name, rationale, and example

### Out of Scope

- `Set#inspect` format change detection — deferred; belongs to a sibling Ruby-4 ticket (CAT-2636/2637/2638) or a future milestone of this gem — *v1 scope is `Hash#inspect` only*
- Error/backtrace message format change detection ([#16495](https://bugs.ruby-lang.org/issues/16495), [#19117](https://bugs.ruby-lang.org/issues/19117)) — deferred for the same reason
- Flagging `hash.inspect` / `"#{hash}"` interpolation / `hash.to_s` in serialization & log paths — *too broad; high false-positive risk. v1 detects only legacy-format string/regexp literals*
- Broad test-context heuristics (scanning all spec files for inspect reliance) — *deferred to keep v1 conservative and baseline-clean*
- Any change to Puppet 8 validation behavior — *Puppet 8 ships Ruby 3.2, which predates the format change; the cop must be additive only*

## Context

- **Origin:** CAT-2635 investigation (David Swan, 2026-06-11) concluded no existing cop fits. Stock RuboCop, `rubocop-performance`, and community/"Ruby 4 cop pack" options were surveyed; none detect reliance on `Hash#inspect` output format. Existing hash cops (`Style/HashSyntax`, `Layout/SpaceInsideHashLiteralBraces`) govern hash *literal source syntax*, not runtime `inspect` output.
- **Why this is inherently heuristic:** RuboCop does static AST analysis. The reliance manifests at runtime as string comparisons against hardcoded literals (`eq("{:a=>1}")`) or interpolation. A cop cannot truly know a string literal represents expected inspect output — so detection is a heuristic keyed on the recognizable legacy format signature inside literals. v1 deliberately picks the **strongest, lowest-noise signal** (legacy-format string/regexp literals) and excludes noisier signals.
- **Format reference:**
  - Ruby ≤ 3.3: `{:x=>1, :"foo-bar"=>2, "baz"=>3}`
  - Ruby ≥ 3.4: `{x: 1, "foo-bar": 2, "baz" => 3}`
- **Version exposure:** Puppet 8 → Ruby 3.2 (unaffected). Exposure begins at Ruby 3.4+ (Puppet 9 / Ruby 4 runtime).
- **Cross-ticket note:** `Hash#inspect` is one of a family of Ruby-4 runtime output-format changes (`Set#inspect`, error/backtrace messages) that share the same static-undetectability problem. v1 of this gem covers only `Hash#inspect`; the architecture should leave room to add sibling cops later without rework.
- **Ecosystem:** Lives in the Puppet/PDK ecosystem (`pdk-private`, `pdk-templates`, `puppet-lint` are sibling repos in the same workspace). Delivered as a standalone gem so it can be versioned and depended on independently.

## Constraints

- **Tech stack**: Ruby gem, RuboCop extension API (cop + spec + config); RSpec for cop specs using RuboCop's cop test helpers.
- **Compatibility**: Must be additive — no false positives on Puppet 8 / Ruby 3.2 module code; no change to existing `pdk validate` behavior when the cop is disabled.
- **Quality bar**: Heuristic by nature — success criterion relaxed (per CAT-2635 investigation) from "zero false positives" to **no false positives on the curated clean-module baseline**.
- **Dependencies**: Two-repo delivery — the gem itself, plus a `pdk-templates` `.rubocop.yml` PR to wire it into `pdk validate`. The template PR depends on a published/loadable gem.
- **Integration**: Loadable as a RuboCop extension via `require:` in `.rubocop.yml`; configurable like any standard cop.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build a new custom cop (not adopt an existing one) | Investigation found no stock/community cop detects `Hash#inspect` output reliance | — Pending |
| v1 scope = `Hash#inspect` only | Matches ticket title; keep first release tight and baseline-clean; siblings (`Set#inspect`, backtraces) deferred | — Pending |
| Detection = legacy-format string/regexp literals only | Strongest, lowest-noise signal; excludes `.inspect`/interpolation to control false positives | — Pending |
| Default severity = convention/refactor, enabled | Visible in `pdk validate` output at lowest friction; non-blocking | — Pending |
| Deliver gem + `pdk-templates` config PR | Cop must actually run in `pdk validate`, not just exist | — Pending |
| Relax "zero FP" → "no FP on curated baseline" | A heuristic cannot guarantee zero FP everywhere; baseline is the testable bar | — Pending |
| Standalone gem named `rubocop-hash_inspect` | Honest about current scope; standard `rubocop-*` extension naming | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-15 after initialization*
