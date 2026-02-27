# frozen_string_literal: true

require_relative "lib/flowengine/cli/version"

Gem::Specification.new do |spec|
  spec.name = "flowengine-cli"
  spec.version = FlowEngine::CLI::VERSION
  spec.authors = ["Konstantin Gredeskoul"]
  spec.email = ["kigster@gmail.com"]

  spec.summary = "Terminal-based interactive wizard runner for FlowEngine flows"
  spec.description = "Provides a TTY-based CLI to run FlowEngine flow definitions interactively, " \
                     "export Mermaid diagrams, and validate flow files."
  spec.homepage = "https://github.com/kigster/flowengine-cli"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kigster/flowengine-cli"
  spec.metadata["changelog_uri"] = "https://github.com/kigster/flowengine-cli/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "dry-cli", "~> 1.0"
  spec.add_dependency "flowengine", "~> 0.1"
  spec.add_dependency "tty-box", "~> 0.7"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-screen", "~> 0.8"
  spec.add_dependency "yard"
end
