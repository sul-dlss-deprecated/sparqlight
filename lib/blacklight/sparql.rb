require 'blacklight/sparql/version'

##
# SparqLight
module Blacklight
  module Sparql
    autoload :Document, 'blacklight/sparql/document'
    autoload :FacetPaginator, 'blacklight/sparql/facet_paginator'
    autoload :Repository, 'blacklight/sparql/repository'
    autoload :Request, 'blacklight/sparql/request'
    autoload :Response, 'blacklight/sparql/response'
    autoload :SearchBuilderBehavior, 'blacklight/sparql/search_builder_behavior'
  end
end
