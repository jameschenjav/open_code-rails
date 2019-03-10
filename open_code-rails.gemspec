lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "open_code/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "open_code-rails"
  spec.version       = OpenCode::Rails::VERSION
  spec.authors       = ["James Chen"]
  spec.email         = ["egustc@gmail.com"]

  spec.summary       = 'Open file in editor in Rails exception pages'
  spec.description   = 'Add an link beside files on exception'
  spec.homepage      = "https://github.com/eGust/open_code-rails"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features|screenshots)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w(lib)

  spec.required_ruby_version = ">= 2.3"
  spec.add_dependency("railties", ">= 4.2")

  spec.add_development_dependency("bundler", ">= 1.10")
  spec.add_development_dependency("rake", "~> 10.0")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("pry-byebug")
  spec.add_development_dependency("rubocop")
end
