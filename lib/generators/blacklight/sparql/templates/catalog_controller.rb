# frozen_string_literal: true
class <%= controller_name.classify %>Controller < ApplicationController

  include Blacklight::Catalog

  configure_blacklight do |config|
    # Class for sending and receiving requests from a search index
    config.repository_class = Blacklight::Sparql::Repository
    
    # Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = ::SearchBuilder

    # Model that describes a Document
    config.document_model = ::SparqlDocument

    # Model that maps search index responses to the blacklight response model
    config.response_model = Blacklight::Sparql::Response

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # Prefix definition for SPARQL queries
    config.sparql_prefixes = {
      nmo: "http://nomisma.org/ontology#",
      skos: "http://www.w3.org/2004/02/skos/core#",
      dcterms: "http://purl.org/dc/terms/",
    }

    # rdf:type of resources managed by this controller
    config.entity_class = "nmo:Denomination"

    # JSON-LD frame used for generating response documents
    config.frame = JSON.parse %({
      "@context": {
        "nmo": "http://nomisma.org/ontology#",
        "skos": "http://www.w3.org/2004/02/skos/core#",
        "dcterms": "http://purl.org/dc/terms/",
        "skos:prefLabel": {"@language": "en"},
        "skos:definition": {"@language": "en"}
      },
      "@type": "nmo:Denomination",
      "dcterms:isPartOf": {
        "@type": "nmo:FieldOfNumismatics"
      }
    })


    # solr field configuration for search results/index views
    config.index.title_field = 'title_display'
    config.index.display_type_field = 'format'

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # Facet fields, may be bound when querying
    # * _field name_ is predicate or other distinguishing identifier
    # * `label` used for human-readible form label
    # * `variable` is the SPARQL variable associated with the field
    # * `patterns` (optional) are SPARQL triple patterns necessary to navigate between `?id` and `variable`. Defaults to a pattern composed of `?id`, `predicate` and `variable`.
    # * `predicate` defaults to _field name_, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
    # * `filter_language` set to true, if the configured language should be used as a filter for the variable result if it is a language-tagged literal.
    config.add_facet_field 'num_label',
      label: 'Numismatics',
      variable: "?num_lab",
      patterns: [
        "?id dcterms:isPartOf ?num",
        "?num a nmo:FieldOfNumismatics",
        "?num skos:prefLabel ?num_lab"
      ],
      filter_language: true

    # Have BL send all facet field names to Sparql, which has been the default
    # previously. Simply remove these lines if you'd rather use Sparql request
    # handler defaults, or have no facets.
    # Note: this is a generic method, not specific to Solr
    config.add_facet_fields_to_solr_request!
    config.add_field_configuration_to_solr_request!

    # Sparql fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    # * _field name_ is predicate or other distinguishing identifier
    # * `variable` is the SPARQL variable associated with the field
    # * `predicate` defaults to field name, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
    # * `patterns` (optional) are SPARQL triple patterns necessary to navigate between `?id` and `variable`. They default to using the _field name_ as the predicate relating `?id` and `variable`. These are also used in CONSTRUCT when generating RDF triples to frame.
    # * `filter_language` set to true, if the configured language should be used as a filter for the variable result if it is a language-tagged literal.
    config.add_index_field 'skos:prefLabel', label: 'Label', variable: "?lab", filter_language: true
    config.add_index_field 'skos:definition', label: 'Definition', variable: "?defn", filter_language: true
    config.add_index_field 'num_label',
      field: 'dcterms:isPartOf',
      helper_method: 'render_numismatics',
      label: 'Numismatics',
      variable: "?num_lab",
      patterns: [
        "?id dcterms:isPartOf ?num",
        "?num a nmo:FieldOfNumismatics",
        "?num skos:prefLabel ?num_lab"
      ],
      filter_language: true

    # Sparql fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'skos:prefLabel', label: 'Label', variable: "?lab", filter_language: true
    config.add_show_field 'skos:definition', label: 'Definition', variable: "?defn", filter_language: true
    config.add_show_field 'num_label',
      field: 'dcterms:isPartOf',
      helper_method: 'render_numismatics',
      label: 'Numismatics',
      variable: "?num_lab",
      patterns: [
        "?id dcterms:isPartOf ?num",
        "?num a nmo:FieldOfNumismatics",
        "?num skos:prefLabel ?num_lab"
      ],
      filter_language: true

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Adds a CONTAINS filter on the specified variable
    # * `field name` is predicate or other distinguishing identifier
    # * `variable` is one or more SPARQL variables associated with the fields to search
    # * `patterns` (optional) are SPARQL triple patterns necessary to filter for matching triples.
    # * `predicate` defaults to _field name_, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
    # * `patterns` (optional) are SPARQL triple patterns necessary filter results based on the search term. Defaults to `"FILTER(CONTAINS(%{variable}, '%{term}'))"`, there `%{lab_term}` is substituted in the. where multiple variables are CONCATenated
    config.add_search_field('all_fields') do |field|
      field.label = 'All Fields'
      field.default = true
      field.variable = %w(?lab ?defn ?num_lab)
      field.patterns = ["FILTER(CONTAINS(STR(CONCAT(?lab, ?defn, ?num_lab)), '%{q}'))"]
    end

    config.add_search_field('label') do |field|
      field.label = 'Label'
      field.variable = "?lab"
      field.patterns = ["FILTER(CONTAINS(STR(?lab), '%{q}'))"]
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field '?lab asc', label: 'Label'
    config.add_sort_field '?defn asc', label: 'Definition'
  end
end
