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

    # Using required_dependency to work around Rails autoloading
    # problems when developing blacklight. Without this, any change
    # to this class breaks other classes in this namespace
    require_dependency 'blacklight/sparql/response/pagination_methods'
    require_dependency 'blacklight/sparql/response/spelling'
    require_dependency 'blacklight/sparql/response/facets'
    #require_dependency 'blacklight/sparql/response/more_like_this'
    #require_dependency 'blacklight/sparql/response/group_response'
    require_dependency 'blacklight/sparql/response/response'
    require_dependency 'blacklight/sparql/response/group'

    include Response
    include PaginationMethods
    include Spelling
    include Facets
    #include MoreLikeThis

    attr_reader :request_params
    attr_accessor :document_model, :blacklight_config

    # @param [Array<Hash>] docs as expanded JSON-LD objects
    # @param [Hash{Symbol => Object}] request_params
    # @param [Hash{Symbol => Object}] options
    # @option options [Integer] :numFound
    # @option options [Hash] :facet_counts
    def initialize(docs, request_params, options = {})
      @request_params = request_params.with_indifferent_access
      self.document_model = options[:sparql_document_model] || options[:document_model] || ::SparqlDocument
      self.blacklight_config = options[:blacklight_config]

      facet_counts = options.fetch(:facet_counts, {})
      super(response: {numFound: options[:numFound], start: self.start, docs: docs},
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

    # SPARQL doesn't support grouping like Solr.
    def grouped?
      false
    end

    def export_formats
      documents.map { |x| x.export_formats.keys }.flatten.uniq
    end

    def method_missing(meth, *args)
      $stderr.puts("Call to Response##{meth}")
      super
    end
  end
end
