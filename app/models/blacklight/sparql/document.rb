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

  # Turn solutions into hashes representing documents. Note a main entity may relate to one or more sub-entities, which themselves may reference one or more sub-entities, etc. Scalar values may be multiple too.
  def self.solutions_to_docs
  end
end
