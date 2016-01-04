# A mixin for making access to the spellcheck component data easy.
#
# Sparql does not provide any spelling hints
#
# response.spelling.words
#
module Blacklight::Sparql::Response::Spelling

  def spelling
    @spelling ||= Base.new(self)
  end

  class Base

    attr :response

    def initialize(response)
      @response = response
    end

    # No spelling suggestions
    def words
      []
    end

  end

end
