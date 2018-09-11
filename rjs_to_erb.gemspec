
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rjs_to_erb/version"

Gem::Specification.new do |spec|
  spec.name          = "rjs_to_erb"
  spec.version       = RjsToErb::VERSION
  spec.authors       = ["Alistair McKinnell"]
  spec.email         = ["alistairm@nulogy.com"]

  spec.summary       = %q{Convert PackManager rjs files to erb.}
  spec.homepage      = "https://github.com/amckinnell/rjs_to_erb"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "astrolabe", "~> 1.3"
  spec.add_runtime_dependency "parser", "~> 2.5"
  spec.add_runtime_dependency "unparser", "~> 0.2"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rubocop", "~> 0.59"
  spec.add_development_dependency "rubocop-rspec", "~> 1.29"
  spec.add_development_dependency "transpec", "~> 3.3"
end
