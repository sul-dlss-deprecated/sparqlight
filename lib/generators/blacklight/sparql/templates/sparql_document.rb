# frozen_string_literal: true
#
# This class encludes everything necessary for dealing with specific SPARQL _Documents_.
class <%= model_name.classify %>
  require_dependency 'blacklight/sparql'

  include Blacklight::Sparql::Document

  self.unique_key = '@id'
end
