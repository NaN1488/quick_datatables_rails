# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quick_datatables_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "quick_datatables_rails"
  spec.version       = QuickDatatablesRails::VERSION
  spec.authors       = ["Nahuel Sciaratta"]
  spec.email         = ["nahuelsciaratta@gmail.com"]
  spec.description   = %q{Easy implementation of datatables}
  spec.summary       = %q{Easy implementation of datatables}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.files = Dir["{app,lib}/**/*"]
  spec.add_dependency "railties"
  spec.add_dependency 'jquery-datatables-rails'
  spec.add_dependency 'kaminari'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
