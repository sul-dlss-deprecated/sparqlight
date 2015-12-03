require 'sparql/client'

module Blacklight::Sparql
  class Repository < Blacklight::AbstractRepository

    ##
    # Find a single entity result (by id) using the document configuration
    # @param [String, RDF::URI] document's IRI
    # @param [Hash] additional query parameters
    # @return [Blacklight::Solr::Response] the SPARQL response object
    def find id, params = {}
      query = %(DESCRIBE <%{id}>)
      require 'byebug'; byebug
      response = send_and_receive query: query, id: id
      raise Blacklight::Exceptions::RecordNotFound.new if enumerable.empty?
      enumerable
    end

    ##
    # Execute a search query against sparql
    # @param [Hash] sparql query parameters
    # @return [Blacklight::Solr::Response] the SPARQL response object
    def search params = {}
      send_and_receive params
    end

    ##
    # Execute a SPARQL query
    # @overload find(endpoint, params)
    #   Execute a SPARQL query at the given endpoint with the parameters
    #   @param [RDF::URI] endpoint (defaults to blacklight_config.sparql_endpoint)
    #   @param [Hash] parameters for SPARQL::Client.query
    # @overload find(params)
    #   @param [Hash] parameters for SPARQL::Client.query
    # @return [Blacklight::Sparql::Response] the SPARQL response object
    def send_and_receive(params = {})
      benchmark("SPARQL fetch", level: :debug) do
        # Query endpoint, interpolating parameters
        res = connection.query(params.fetch(:query) % params)

        sparql_response = blacklight_config.response_model.new(res, params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)

        Blacklight.logger.debug {"SPARQL query: #{endpoint} #{params.fetch(:query) % params}"}
        Blacklight.logger.debug {"SPARQL response: #{sparql_response.inspect}"} if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
        sparql_response
      end
    rescue SPARQL::Client::ServerError => e
      raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to SPARQL server: #{e.inspect}")
    rescue SPARQL::Client::MalformedQuery, SPARQL::Client::ClientError => e
      raise Blacklight::Exceptions::InvalidRequest.new(e.message)
    end

  protected

    def build_connection
      case connection_config
      when Hash
        config = if connection_config[:repository]
          require 'rdf/do'
          require 'do_sqlite3'

          # Open a local repository and use as a SPARQL client
          SPARQL::Client.new RDF::DataObjects::Repository.new(connection_config[:repository])
        elsif connection_config[:url]
          SPARQL::Client.new(connection_config[:url])
        else
          raise "Expected :repository for RDF::DataObjects initializer for local repository or :url for a remote SPARQL endpoint"
        end
      else
        SPARQL::Client.new(connection_config)
      end
    end
  end
end