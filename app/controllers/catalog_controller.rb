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

    # SPARQL Configurations (config/initializers/sparql_config.rb)
    SparqlConfig.sparql_config(config)

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

  end

end

