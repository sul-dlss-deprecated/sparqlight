##
##
# = Introduction
# Blacklight::Sparql::Document is the module with logic for a class representing an individual document returned from SPARQL results.  It can be added in to any local class you want, but in default Blacklight a SparqlDocument class is provided for you which is pretty much a blank class "include"ing Blacklight::Sparql::Document.
#
# Blacklight::Sparql::Document provides some DefaultFinders.
#
# It also provides support for Document Extensions, which advertise supported
# transformation formats.
#

module Blacklight::Sparql::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim

  # FIXME: 
  #def has_highlight_field? k
  #  return false if response['highlighting'].blank? or response['highlighting'][self.id].blank?
  #  
  #  response['highlighting'][self.id].key? k.to_s
  #end

  #def highlight_field k
  #  response['highlighting'][self.id][k.to_s].map(&:html_safe) if has_highlight_field? k
  #end

end
