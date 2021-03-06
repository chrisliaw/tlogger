require_relative 'lib/tlogger/version'

Gem::Specification.new do |spec|
  spec.name          = "tlogger"
  spec.version       = Tlogger::VERSION
  spec.authors       = ["Chris"]
  spec.email         = ["chrisliaw@antrapol.com"]

  spec.summary       = %q{Logger that added contextual information to the log messages}
  spec.description   = %q{Logger that provides some control over how the log messages are being displayed with conditionally enable and disable certain log messages from showing based on configurations}
  spec.homepage      = "https://github.com/chrisliaw/tlogger"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.licenses      = ["MIT"]

  #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
