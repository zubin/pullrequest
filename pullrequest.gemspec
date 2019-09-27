# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pullrequest/version'

Gem::Specification.new do |spec|
  spec.name          = "pullrequest"
  spec.version       = Pullrequest::VERSION
  spec.authors       = ["Zubin Henner"]
  spec.email         = ["zubin@rubidium.com.au"]

  spec.summary       = %q{CLI for submitting Bitbucket pull requests}
  spec.homepage      = "https://github.com/zubin/pullrequest"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor'
  spec.add_dependency 'json'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'pry'
end
