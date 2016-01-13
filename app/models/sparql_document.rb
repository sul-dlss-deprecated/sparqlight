# -*- encoding : utf-8 -*-
#
# This class encludes everything necessary for dealing with specific SPARQL _Documents_.
class SparqlDocument 
  require_dependency 'blacklight/sparql'

  include Blacklight::Sparql::Document

  self.unique_key = '@id'
end
