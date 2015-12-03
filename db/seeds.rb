# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Load Nomisma triples
connection = Blacklight.default_index.connection
repo = connection.url
raise "Expected connection to a repository" unless repo.is_a?(RDF::Repository)
require 'byebug'; byebug
repo.load("db/nomisma.ttl")
$stderr.puts "Loaded #{repo.count} triples"
