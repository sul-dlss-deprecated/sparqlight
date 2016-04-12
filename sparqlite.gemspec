# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blacklight/sparql/version'

Gem::Specification.new do |spec|
  spec.name          = "sparqlight"
  spec.version       = Blacklight::Sparql::VERSION
  spec.authors       = ["Gregg Kellogg"]
  spec.email         = ["gregg@greggkellogg.net"]
  spec.summary       = %q{SPARQL extension for Blacklight}
  spec.homepage      = "https://github.com/projectblacklight/sparqlight"
  spec.license       = "Apache 2.0"

  spec.files         = %w(Rakefile README.md LICENSE VERSION) + Dir['{app,lib}/**/*']
  spec.require_paths = ["lib"]

  spec.add_dependency "rails",          '~> 4.2'
  spec.add_dependency 'blacklight',     '~> 6.0'
  spec.add_dependency 'json-ld',        '~> 1.99'
  spec.add_dependency 'rdf',            '~> 1.99'
  spec.add_dependency "rdf-turtle",     '~> 1.99'
  spec.add_dependency 'sparql-client',  '~> 1.99'

  spec.add_development_dependency "sparql",    '~> 1.99'
  spec.add_development_dependency 'rdf-mongo', '~> 1.99'
  spec.add_development_dependency 'bson_ext'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'rspec-activemodel-mocks'
  spec.add_development_dependency 'rspec-collection_matchers'
 end