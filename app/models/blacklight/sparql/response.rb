module Blacklight::Sparql
  class Response

    # Using required_dependency to work around Rails autoloading
    # problems when developing blacklight. Without this, any change
    # to this class breaks other classes in this namespace
    #require_dependency 'blacklight/sparql/response/pagination_methods'
    #require_dependency 'blacklight/sparql/response/spelling'
    #require_dependency 'blacklight/sparql/response/facets'
    #require_dependency 'blacklight/sparql/response/more_like_this'
    #require_dependency 'blacklight/sparql/response/group_response'
    require_dependency 'blacklight/sparql/response/group'

    #include PaginationMethods
    #include Spelling
    #include Facets
    #include MoreLikeThis

    attr_reader :request_params
    attr_accessor :document_model, :blacklight_config

    # @param [RDF::Queryable::Solutions] solutions
    # @param [Hash{Symbol => Object}] request_params
    # @param [Hash{Symbol => Object}] options
    def initialize(solutions, request_params, options = {})
      @solutions = solutions
      @request_params = request_params.with_indifferent_access
      self.document_model = options[:sparql_document_model] || options[:document_model] || ::SparqlDocument
      self.blacklight_config = options[:blacklight_config]
    end

    def params
      request_params
    end

    def documents
      @documents ||= @solutions.collect{|solution| document_model.new(solution, self) }
    end
    alias_method :docs, :documents

    def method_missing(meth, *args)
      $stderr.puts("Call to Response##{meth}")
      super
    end
  end
end
