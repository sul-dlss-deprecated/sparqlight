require 'sparql/client'
require 'blacklight/sparql'

module Blacklight::Sparql
  class Repository < Blacklight::AbstractRepository

    ##
    # Find a single entity result (by id) using the document configuration
    # @param [String, RDF::URI] document's IRI
    # @param [Hash] additional query parameters
    # @return [Blacklight::Solr::Response] the SPARQL response object
    def find id, params = {}
      # Document query with a restriction on
      # Build query using defined prefixes, id, and index fields
      query = blacklight_config.sparql_prefixes.map {|p, u| "PREFIX #{p}: <#{u}>"}.join("\n")
      query += "\nSELECT ?id " + blacklight_config.show_fields.values.map(&:variable).join(' ')
      query += "\nWHERE {\n"
      query += "  ?id a #{blacklight_config.entity_class} .\n"
      blacklight_config.show_fields.values.each do |field|
        query += "  ?id #{field.field} #{field.variable} .\n"
      end

      # Add filters
      blacklight_config.show_fields.values.select(&:filter_language).each do |field|
        query += "  FILTER(LANG(#{field.variable}) = 'en')\n"
      end
      query += "  FILTER(?id = IRI('#{id}'))\n"
      query += "}"
      
      response = send_and_receive query: query
      raise Blacklight::Exceptions::RecordNotFound.new if response.documents.empty?
      response
    end

    ##
    # Execute a search query against sparql.
    #
    # This needs several queries:
    #   * one for the paginated results
    #   * one for the count of all results
    #   * one for each of the facets to get possible values
    #
    # @param [Hash] params sparql query parameters
    # @option params [String] :query
    #   SPARQL query should return result set. Query string can be parameterized
    #   with arguments in `params` interpolated using `String#%`.
    # @return [Blacklight::Solr::Response] the SPARQL response object
    def search params = {}
      # Document query with a restriction on
      # Build query using defined prefixes, id, and index fields
      prefixes = blacklight_config.sparql_prefixes.map {|p, u| "PREFIX #{p}: <#{u}>"}.join("\n")
      query = "\nSELECT ?id " + params[:show_fields].map(&:variable).join(' ')

      where =  "\nWHERE {\n"
      where += "  ?id a #{blacklight_config.entity_class} .\n"
      params[:show_fields].each do |field|
        query += "  ?id #{field.field} #{field.variable} .\n"
      end

      # Add Lanaugage filters
      params[:show_fields].select(&:filter_language).each do |field|
        where += "  FILTER(LANG(#{field.variable}) = 'en')\n"
      end

      # Add facets
      #blacklight_config.facet_fields.values.each do |field|
      #  where += "  FILTER(LANG(#{field.variable}) = 'en')\n"
      #end

      # Pagination

      where += "}"

      # Get record count
      res = connection.query(prefixes + "SELECT (COUNT(?id) as ?count)\n" + where)
      count = (res.first || {})[:count].to_i

      results = send_and_receive query: prefixes + "SELECT (COUNT(?id) as ?count)\n" + where

      send_and_receive query: query, count: count
    end

    ##
    # Execute a SPARQL query returning `RDF::Query::Solutions`
    #
    # @param [Hash] params for SPARQL::Client.query
    # @option params [String] :query
    #   SPARQL query should return result set. Query string can be parameterized
    #   with arguments in `params` interpolated using `String#%`.
    # @option params [Hash] :facet_counts
    # @option params [Hash] :count record count, defaults to number of results
    # @return [Blacklight::Sparql::Response] the SPARQL response object
    def send_and_receive(params = {})
      benchmark("SPARQL fetch", level: :debug) do
        # Query endpoint, interpolating parameters
        res = connection.query(params.fetch(:query) % params)

        facet_counts = params.delete(:facet_counts) || {}
        count = params.delete(:count) || res.length

        opts = {
          facet_counts: facet_counts,
          numFound: count,
          document_model: blacklight_config.document_model,
          blacklight_config: blacklight_config
        }
        sparql_response = blacklight_config.response_model.new(res, params, opts)

        Blacklight.logger.debug {"SPARQL query: #{params.fetch(:query) % params}"}
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