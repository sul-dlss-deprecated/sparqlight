module Blacklight::Sparql
  class Response < HashWithIndifferentAccess

    # Mirror a certain amount of the Solr response:
    #{
    #  "response": {
    #    "numFound": 1,
    #    "start": 0,
    #    "docs": [
    #      {"id": "", ...}
    #    ]
    #  },
    #  'facet_counts'=>{
    #    'facet_queries'=>{},
    #    'facet_fields'=>{
    #      'cat'=>['electronics',14,'memory',3,'card',2,'connector',2,'drive',2,'graphics',2,'hard',2,'monitor',2,'search',2,'software',2],
    #      'manu'=>['inc',8,'apach',2,'belkin',2,'canon',2,'comput',2,'corp',2,'corsair',2,'foundat',2,'microsystem',2,'softwar',2]
    #    },
    #    'facet_dates'=>{}
    #  }
    #}

    # FIXME: to get numFound requires two queries, one with a COUNT, and another with OFFSET/LIMIT
    # FIXME: facets don't come naturally in response, they should be provided from the repository or document model based on a one-time query. This may require one select per facet to get back the distinct values; not sure if the facet values should be reduced by the query results, though.

    # Using required_dependency to work around Rails autoloading
    # problems when developing blacklight. Without this, any change
    # to this class breaks other classes in this namespace
    #require_dependency 'blacklight/sparql/response/pagination_methods'
    #require_dependency 'blacklight/sparql/response/spelling'
    #require_dependency 'blacklight/sparql/response/facets'
    #require_dependency 'blacklight/sparql/response/more_like_this'
    #require_dependency 'blacklight/sparql/response/group_response'
    require_dependency 'blacklight/sparql/response/response'
    require_dependency 'blacklight/sparql/response/group'

    include Response
    #include PaginationMethods
    #include Spelling
    #include Facets
    #include MoreLikeThis

    attr_reader :request_params
    attr_accessor :document_model, :blacklight_config

    # @param [RDF::Queryable::Solutions] solutions
    # @param [Hash{Symbol => Object}] request_params
    # @param [Hash{Symbol => Object}] options
    # @option options [Integer] :numFound
    # @option options [Hash] :facet_counts
    def initialize(solutions, request_params, options = {})
      @request_params = request_params.with_indifferent_access
      self.document_model = options[:sparql_document_model] || options[:document_model] || ::SparqlDocument
      self.blacklight_config = options[:blacklight_config]

      facet_counts = options.fetch(:facet_counts, {})
      super(response: {numFound: options[:numFound], start: self.start, docs: solutions.map(&:to_hash)},
            facet_counts: facet_counts
      )
    end

    def params
      request_params
    end

    def start
      params[:start].to_i
    end

    def rows
      params[:rows].to_i
    end

    def sort
      params[:sort]
    end

    def documents
      @documents ||= (response['docs'] || []).collect{|doc| document_model.new(doc, self) }
    end
    alias_method :docs, :documents

    def method_missing(meth, *args)
      $stderr.puts("Call to Response##{meth}")
      super
    end
  end
end
