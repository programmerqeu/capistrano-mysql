# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/mysql/version'

# gemspec :development_group => :dev

Gem::Specification.new do |spec|
  spec.name          = "capistrano-mysql"
  spec.version       = Capistrano::Mysql::VERSION
  spec.authors       = ["André Lademann"]
  spec.email         = ["andre@programmerq.eu"]
  spec.description   = %q{Deploy mysql databases}
  spec.summary       = %q{Deploy mysql databases}
  spec.homepage      = "http://github.com/programmerqeu/capistrano-mysql"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency							"capistrano", ">= 2.13.5","<= 2.15.4"
  spec.add_dependency							"capistrano_colors", ">= 0.5.5"
  spec.add_dependency							"capistrano-ext", ">= 1.2.1"
  spec.add_dependency							"railsless-deploy", "~> 1.1.2"
	spec.add_dependency							"ruby-progressbar", "1.0.2"

  spec.add_development_dependency "railsless-deploy", "~> 1.1.2"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
