# -*- encoding : utf-8 -*-
class CatalogController < ApplicationController  

  include Blacklight::Catalog

  configure_blacklight do |config|
    # SPARQL Configurations (config/initializers/sparql_config.rb)
    SparqlConfig.sparql_config(config)

    # items to show per page, each number in the array represent another option to choose from.
    #config.per_page = [10,20,50,100]

  end

end

