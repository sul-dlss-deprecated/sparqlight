# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController  

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

    # Prefix definition for SPARQL queries
    config.sparql_prefixes = {
      foaf: "http://xmlns.com/foaf/0.1/",
      dc: "http://purl.org/dc/elements/1.1/",
      event: "http://purl.org/NET/c4dm/event.owl#",
      mo: "http://purl.org/ontology/mo/",
      rdfs: "http://www.w3.org/2000/01/rdf-schema#"
    }

    config.entity_class = "mo:Performance"

    # JSON-LD frame used for generating response documents
    config.frame = JSON.parse %({
      "@context": {
        "foaf": "http://xmlns.com/foaf/0.1/",
        "dc": "http://purl.org/dc/elements/1.1/",
        "event": "http://purl.org/NET/c4dm/event.owl#",
        "mo": "http://purl.org/ontology/mo/",
        "rdfs": "http://www.w3.org/2000/01/rdf-schema#"
      },
      "@type": "mo:Performance",
      "event:sub_event": {
        "@type": "mo:Performance",
        "mo:performance_of": {
          "@type": "mo:MusicalWork"
        }
      },
      "mo:performer": {
        "@type": "mo:MusicArtist"
      }
    })

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # Facet fields, may be bound when querying
    # * _field name_ is predicate or other distinguishing identifier
    # * `label` used for human-readible form label
    # * `variable` is the SPARQL variable associated with the field
    # * `patterns` (optional) are SPARQL triple patterns necessary to navigate between `?id` and `variable`. Defaults to a pattern composed of `?id`, `predicate` and `variable`.
    # * `predicate` defaults to _field name_, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
    # * `filter_language` set to true, if the configured language should be used as a filter for the variable result if it is a language-tagged literal.
    config.add_facet_field 'performer_name',
      field: '?performer_name',
      label: 'Performer',
      variable: "?performer_name",
      :patterns => [
        "?id mo:performer ?performer",
        "?performer a mo:MusicArtist; foaf:name ?performer_name"
      ]

    config.add_facet_field 'work_title',
      field: '?work_title',
      label: 'Musical Work',
      variable: "?work_title",
      :patterns => [
        "?id event:sub_event ?perf_work",
        "?perf_work mo:performance_of ?work",
        "?work a mo:MusicalWork; dc:title ?work_title"
      ]

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
    config.add_index_field 'perf_label', predicate: 'rdfs:label', label: 'Label', variable: "?perf_label"
    config.add_index_field 'perf_place', predicate: 'event:place', label: 'Place', variable: "?perf_place"
    config.add_index_field 'work_title',
      helper_method: 'render_work',
      :label => 'Musical Work',
      :variable => "?work_title",
      :patterns => [
        "?id event:sub_event ?perf_work",
        "?perf_work mo:performance_of ?work",
        "?work a mo:MusicalWork; dc:title ?work_title"
      ]
    config.add_index_field 'performer_name',
      field: '?performer_name',
      label: 'Performer',
      variable: "?performer_name",
      :patterns => [
        "?id mo:performer ?performer",
        "?performer a mo:MusicArtist; foaf:name ?performer_name"
      ]

    # Sparql fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'perf_label', predicate: 'rdfs:label', label: 'Label', variable: "?perf_label"
    config.add_show_field 'perf_place', predicate: 'event:place', label: 'Place', variable: "?perf_place"
    config.add_show_field 'work_title',
      helper_method: 'render_work',
      :label => 'Musical Work',
      :variable => "?work_title",
      :patterns => [
        "?id event:sub_event ?perf_work",
        "?perf_work mo:performance_of ?work",
        "?work a mo:MusicalWork; dc:title ?work_title"
      ]
    config.add_show_field 'performer_name',
      field: '?performer_name',
      label: 'Performer',
      variable: "?performer_name",
      :patterns => [
        "?id mo:performer ?performer",
        "?performer a mo:MusicArtist; foaf:name ?performer_name"
      ]

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
      field.patterns = ["FILTER(CONTAINS(STR(CONCAT(?perf_label, ?perf_place, ?work_title, ?performer_name)), '%{q}'))"]
    end

    config.add_search_field('performance') do |field|
      field.label = 'Performance'
      field.variable = "?perf_label"
      field.patterns = ["FILTER(CONTAINS(STR(?perf_label), '%{q}'))"]
    end

    config.add_search_field('place') do |field|
      field.label = 'Place'
      field.variable = "?perf_place"
      field.patterns = ["FILTER(CONTAINS(STR(?perf_place), '%{q}'))"]
    end

    config.add_search_field('work') do |field|
      field.label = 'Work'
      field.variable = "?work_title"
      field.patterns = ["FILTER(CONTAINS(STR(?work_title), '%{q}'))"]
    end

    config.add_search_field('performer') do |field|
      field.label = 'Performer'
      field.variable = "?performer_name"
      field.patterns = ["FILTER(CONTAINS(STR(?performer_name), '%{q}'))"]
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field '?perf_label asc', label: 'Performance'
    config.add_sort_field '?perf_place asc', label: 'Place'
    config.add_sort_field '?work_title asc', label: 'Work'
    config.add_sort_field '?performer_name asc', label: 'Performer'
  end

end 
