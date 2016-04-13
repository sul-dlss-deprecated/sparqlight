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
if repo.is_a?(RDF::Repository)
  repo.clear!
  require 'rdf/turtle'
  RDF::Reader.open(Rails.env == "test" ? "db/nomisma.ttl" : "db/nomisma-full.ttl") do |reader|
    reader.each_statement do |statement|
      begin
        repo.insert statement
      rescue
        $stderr.write "e"
      end
    end
  end
  $stderr.puts "Loaded #{repo.count} triples"
end