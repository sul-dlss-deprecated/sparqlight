# -*- encoding : utf-8 -*-
module SparqlConfig

  ENTITY_CLASS = "bf:Instance".freeze

  BASE_URI = 'http://ld4p-test.stanford.edu/'.freeze

  # Ontologies
  BIBFRAME = 'http://id.loc.gov/ontologies/bibframe/'.freeze
  DCTERMS = 'http://purl.org/dc/terms/'.freeze
  MADSRDF = 'http://www.loc.gov/mads/rdf/v1#'.freeze
  SKOS = 'http://www.w3.org/2004/02/skos/core#'.freeze

  # Prefix definition for SPARQL queries
  SPARQL_PREFIXES = {
    bf: BIBFRAME,
    dcterms: DCTERMS,
    mads: MADSRDF,
    skos: SKOS,
  }.freeze

  # One method to rule them all
  def self.sparql_config(config)
    config.sparql_prefixes = SparqlConfig::SPARQL_PREFIXES
    config.entity_class = SparqlConfig::ENTITY_CLASS
    config.frame = SparqlConfig.json_frame
    SparqlConfig.facet_fields(config)
    SparqlConfig.index_fields(config)
    SparqlConfig.show_fields(config)
    SparqlConfig.search_fields(config)
    SparqlConfig.sort_fields(config)
  end

  # JSON-LD frame used for generating response documents
  def self.json_frame
    JSON.parse %({
      "@context": {
        "bf": "#{BIBFRAME}",
        "dcterms": "#{DCTERMS}",
        "mads": "#{MADSRDF}",
        "skos": "#{SKOS}",
        "skos:prefLabel": {"@language": "en"},
        "skos:definition": {"@language": "en"}
      },
      "@type": "#{ENTITY_CLASS}"
    })
  end

  # Facet fields, may be bound when querying
  # * _field name_ is predicate or other distinguishing identifier
  # * `label` used for human-readible form label
  # * `variable` is the SPARQL variable associated with the field
  # * `patterns` (optional) are SPARQL triple patterns necessary to navigate between `?id` and `variable`. Defaults to a pattern composed of `?id`, `predicate` and `variable`.
  # * `predicate` defaults to _field name_, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
  # * `filter_language` set to true, if the configured language should be used as a filter for the variable result if it is a language-tagged literal.
  def self.facet_fields(config)
    config.add_facet_field 'topic_label',
                           label: 'Topics',
                           variable: '?topicLabel',
                           patterns: [
                             '?id a bf:Instance',
                             '?id bf:instanceOf ?work',
                             '?work bf:subject ?topic',
                             '?topic a bf:Topic',
                             '?topic mads:authoritativeLabel ?topicLabel'
                           ],
                           filter_language: true

    # Have BL send all facet field names to Sparql, which has been the default
    # previously. Simply remove these lines if you'd rather use Sparql request
    # handler defaults, or have no facets.
    # Note: this is a generic method, not specific to Solr
    config.add_facet_fields_to_solr_request!
    config.add_field_configuration_to_solr_request!
  end

  # Sparql fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display
  # * _field name_ is predicate or other distinguishing identifier
  # * `variable` is the SPARQL variable associated with the field
  # * `predicate` defaults to field name, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
  # * `patterns` (optional) are SPARQL triple patterns necessary to navigate between `?id` and `variable`. They default to using the _field name_ as the predicate relating `?id` and `variable`. These are also used in CONSTRUCT when generating RDF triples to frame.
  # * `filter_language` set to true, if the configured language should be used as a filter for the variable result if it is a language-tagged literal.
  def self.index_fields(config)
    # config.add_index_field 'skos:prefLabel',
    #                        label: 'Label',
    #                        variable: "?lab",
    #                        filter_language: true
    # config.add_index_field 'skos:definition',
    #                        label: 'Definition',
    #                        variable: "?defn",
    #                        filter_language: true
    config.add_index_field 'subject',
                           label: 'Subject',
                           field: 'bf:subject',
                           helper_method: 'render_subject',
                           variable: '?subjectLabel',
                           patterns: [
                             '?id a bf:Instance',
                             '?id bf:instanceOf ?work',
                             '?work bf:subject ?topic',
                             '?topic a bf:Topic',
                             '?topic mads:authoritativeLabel ?topicLabel'
                           ],
                           filter_language: true
  end

  # Sparql fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display
  def self.show_fields(config)
    # config.add_show_field 'skos:prefLabel', label: 'Label', variable: "?lab", filter_language: true
    # config.add_show_field 'skos:definition', label: 'Definition', variable: "?defn", filter_language: true
    # config.add_show_field 'num_label',
    #   field: 'dcterms:isPartOf',
    #   helper_method: 'render_numismatics',
    #   label: 'Numismatics',
    #   variable: "?num_lab",
    #   patterns: [
    #     "?id dcterms:isPartOf ?num",
    #     "?num a nmo:FieldOfNumismatics",
    #     "?num skos:prefLabel ?num_lab"
    #   ],
    #   filter_language: true

    config.add_show_field 'subject',
                          label: 'Subject',
                          field: 'bf:subject',
                          helper_method: 'render_subject',
                          variable: '?subjectLabel',
                          patterns: [
                            '?id a bf:Instance',
                            '?id bf:instanceOf ?work',
                            '?work bf:subject ?topic',
                            '?topic a bf:Topic',
                            '?topic mads:authoritativeLabel ?topicLabel'
                          ],
                          filter_language: true

  end

  # "fielded" search configuration. Used by pulldown among other places.
  # For supported keys in hash, see rdoc for Blacklight::SearchFields
  #
  # Adds a CONTAINS filter on the specified variable
  # * `field name` is predicate or other distinguishing identifier
  # * `variable` is one or more SPARQL variables associated with the fields to search
  # * `patterns` (optional) are SPARQL triple patterns necessary to filter for matching triples.
  # * `predicate` defaults to _field name_, but may be set separately if multiple fields use the same predicate (i.e., in different entities)
  # * `patterns` (optional) are SPARQL triple patterns necessary filter results based on the search term. Defaults to `"FILTER(CONTAINS(%{variable}, '%{term}'))"`, there `%{lab_term}` is substituted in the. where multiple variables are CONCATenated
  def self.search_fields(config)
    # config.add_search_field('all_fields') do |field|
    #   field.label = 'All Fields'
    #   field.default = true
    #   field.variable = %w(?lab ?defn ?num_lab)
    #   field.patterns = ["FILTER(CONTAINS(STR(CONCAT(?lab, ?defn, ?num_lab)), '%{q}'))"]
    # end

    # config.add_search_field('label') do |field|
    #   field.label = 'Label'
    #   field.variable = "?lab"
    #   field.patterns = ["FILTER(CONTAINS(STR(?lab), '%{q}'))"]
    # end
  end

  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  def self.sort_fields(config)
    # config.add_sort_field '?lab asc', label: 'Label'
    # config.add_sort_field '?defn asc', label: 'Definition'
  end

end 
