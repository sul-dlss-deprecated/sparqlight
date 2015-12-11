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
      nmo: "http://nomisma.org/ontology#",
      skos: "http://www.w3.org/2004/02/skos/core#"
    }

    config.entity_class = "nmo:Denomination"

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

    # Facet fields, may be bound when querying
    config.add_facet_field 'skos:prefLabel', :label => 'Label', :variable => "?lab", :filter_language => true
    config.add_facet_field 'skos:definition', :label => 'Definition', :variable => "?defn", :filter_language => true

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'skos:prefLabel', :label => 'Label', :variable => "?lab", :filter_language => true
    config.add_index_field 'skos:definition', :label => 'Definition', :variable => "?defn", :filter_language => true

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    config.add_show_field 'skos:prefLabel', :label => 'Label', :variable => "?lab", :filter_language => true
    config.add_show_field 'skos:definition', :label => 'Definition', :variable => "?defn", :filter_language => true

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    #config.add_search_field 'all_fields', :label => 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    #config.add_search_field('title') do |field|
    #  # solr_parameters hash are sent to Solr as ordinary url query params. 
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
    #
    #  # :solr_local_parameters will be sent using Solr LocalParams
    #  # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    #  # Solr parameter de-referencing like $title_qf.
    #  # See: http://wiki.apache.org/solr/LocalParams
    #  field.solr_local_parameters = { 
    #    :qf => '$title_qf',
    #    :pf => '$title_pf'
    #  }
    #end
    
    #config.add_search_field('author') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #  field.solr_local_parameters = { 
    #    :qf => '$author_qf',
    #    :pf => '$author_pf'
    #  }
    #end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    #config.add_search_field('subject') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    #  field.qt = 'search'
    #  field.solr_local_parameters = { 
    #    :qf => '$subject_qf',
    #    :pf => '$subject_pf'
    #  }
    #end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field '?lab asc', :label => 'Label'
    config.add_sort_field '?defn asc', :label => 'Definition'
  end

end 
