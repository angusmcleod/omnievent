# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "omnievent/version"

Gem::Specification.new do |spec|
  spec.name = "omnievent"
  spec.version = OmniEvent::VERSION
  spec.authors = ["Angus McLeod"]
  spec.email = ["angus@pavilion.tech"]
  spec.description = "Manage events from any calendar, event discovery, event ticketing,
    event management, social network or video conferencing provider."
  spec.summary = "Manage events from multiple providers."
  spec.homepage = "https://github.com/paviliondev/omnievent"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "activesupport", "~> 4.2.6"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_dependency "hashie", ">= 3.4.6"
  spec.add_dependency "iso-639", "~> 0.3.5"
  spec.add_dependency "tzinfo", "~> 1.1"
end
