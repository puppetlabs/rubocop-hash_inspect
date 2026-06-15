# frozen_string_literal: true

require_relative "lib/rubocop/hash_inspect/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-hash_inspect"
  spec.version       = RuboCop::HashInspect::VERSION
  spec.authors       = ["Puppet"]
  spec.email         = ["puppet@puppet.com"]

  spec.summary       = "RuboCop extension that flags reliance on legacy Hash#inspect output format."
  spec.description   = <<~DESC
    A RuboCop cop that statically detects Ruby code relying on the pre-Ruby 3.4
    Hash#inspect output format (e.g. {:sym=>1}). Ruby 3.4 changed Hash#inspect to
    produce {sym: 1, "str" => 2}, breaking tests that hardcode the old format.
    Run as part of `pdk validate` to catch incompatibilities before upgrading to
    Puppet 9 (Ruby 4).
  DESC
  spec.homepage      = "https://github.com/puppetlabs/rubocop-hash_inspect"
  spec.license       = "Apache-2.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri"               => spec.homepage,
    "source_code_uri"            => spec.homepage,
    "changelog_uri"              => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"            => "#{spec.homepage}/issues",
    "rubygems_mfa_required"      => "true",
    "default_lint_roller_plugin" => "RuboCop::HashInspect::Plugin"
  }

  # D-15: reject filter — ship only lib/, config/, LICENSE, README, CHANGELOG
  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec|\.github|\.planning)/|^\.|^bin/})
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller",   "~> 1.1"
  spec.add_dependency "rubocop",       ">= 1.72.2", "< 2.0"
  spec.add_dependency "rubocop-ast",   ">= 1.45.1", "< 2.0"

  spec.add_development_dependency "rake",         "~> 13.4"
  spec.add_development_dependency "rspec",        "~> 3.13"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
end
