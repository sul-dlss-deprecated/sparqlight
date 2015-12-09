# -*- encoding : utf-8 -*-
#
# This class encludes everything necessary for dealing with specific SPARQL _Documents_. This includes a basic SPARQL query with each column from the result set being a field within the document.
class SparqlDocument 
  require_dependency 'blacklight/sparql'

  include Blacklight::Sparql::Document

  # Coins enties have an ID, label and definition, restricted to a specific language
  # FIXME: language a facet or configured?
  DOC_QUERY = %(
    PREFIX nmo: <http://nomisma.org/ontology#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

    SELECT ?id ?lab ?def
    WHERE {
      ?id a nmo:Denomination;
        skos:prefLabel ?lab;
        skos:definition ?def .
        FILTER(LANG(?lab) = '%{language}')
        FILTER(LANG(?def) = '%{language}')
        %{modifier}
    }
  )

  # Map a given `RDF::Query::Solution` to a hash
  def initialize(solution = RDF::Query::Solution.new, response=nil)
    super(solution.to_hash, response)
  end
end
