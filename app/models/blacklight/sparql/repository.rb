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
      search params.merge(id: id, fields: blacklight_config.show_fields)
    end

    ##
    # Execute a search query against sparql.
    #
    # This needs several queries:
    #   * one for the paginated entities
    #   * one for each entity with indexed fields
    #   * one for the count of all results
    #   * one for each of the facets to aggregated values with counts
    #
    # @note: Because SPARQL LIMIT is for the number of solutions, a single entity may result in mulitple solutions, so we need to separate the offset/limit for entities from the fields necessary to show each entity
    #
    # @param [Hash] params sparql query parameters
    # @option params [Hash{String => Array<String>}] :facet_values
    #   List of bound facets by variable, with individual or multiple values
    # @option params [Hash{String => Hash}] :search
    #   Configuration for each search query. Based on the field definition with `:q` added for the value to search on.
    # @option params [Hash{String => Hash}] :facets
    #   Configuration for each facet aggregation query including sorting, offset/limit, and facet value prefix
    # @option params [Hash] :fields
    #   Fields to show, defaults to `blacklight_config.index_fields`
    # @option params [Integer] :rows (10)
    #   Number of entities to return
    # @option params [Integer] :start
    #   Index into entities for offset/limit
    # @return [Blacklight::Solr::Response] the SPARQL response object
    def search params = {}
      # Document query with a restriction on
      # Build query using defined prefixes, id, and index fields
      fields = params.fetch(:fields, blacklight_config.index_fields)
      prefixes = blacklight_config.sparql_prefixes.map {|p, u| "PREFIX #{p}: <#{u}>"}.join("\n")
      index_query =  "\nSELECT DISTINCT ?id\n"
      construct = "\nCONSTRUCT {\n"
      where =  "\nWHERE {\n"

      construct += "  ?id a #{blacklight_config.entity_class} .\n"
      where     += "  ?id a #{blacklight_config.entity_class} .\n"
      fields.each_value do |field|
        pattern = case field.patterns
        when String
          field.patterns
        when Array
          field.patterns.join(" .\n")
        else
          pred = field.predicate || field.field
          "  ?id #{pred} #{field.variable}"
        end + " .\n"
        construct += pattern
        where     += pattern
      end
      construct += "}\n"

      # Add Lanaugage filters
      # FIXME: not 'en', but configured language, defaulting to 'en'
      fields.values.select(&:filter_language).each do |field|
        where += "  FILTER(langMatches(LANG(#{field.variable}), 'en'))\n"
      end

      # Add search terms
      # FIXME escape filter values
      # FIXME non-string values?
      if search_field = params[:search]
        patterns = search_field[:patterns]
        patterns ||= case search_field[:variable]
        when Array
          ["FILTER(CONTAINS(COALESCE(#{search_field[:variable].join(',')}), '%{q}'))"]
        when nil
          raise "repository search requires patterns or variable"
        else
          ["FILTER(CONTAINS(#{search_field[:variable]}, '%{q}'))"]
        end
        patterns.each do |pattern|
          where += pattern % {q: search_field[:q]}
        end
      end

      # Add facet values
      # FIXME escape filter values
      params.fetch(:facet_values, {}).each do |variable, value|
        where += case value
        when Array
          values = value.map {|v| "'#{v}'"}.join(', ')
          "  FILTER(#{variable} IN(#{values}))\n"
        when String
          "  FILTER(#{variable} = '#{value}')\n"
        else
          ""
        end
      end

      # Get record count
      count = case
      when params[:rows] == 0 then 0
      when params[:id] then 1
      else
        res = connection.query(prefixes + "SELECT (COUNT(?id) as ?__count__)\n" + where + "}")
        (res.first || {})[:__count__].to_i
      end

      # Get paginated rows and individual associated documents
      docs = if params[:id]
        # Getting a single entity
        # FIXME: if we used a sub-select, this could be done in a single query
        # Get back constructed entities as a frame
        query = prefixes + construct + where +
        "  FILTER(?id = #{RDF::URI(params[:id]).to_ntriples})\n}\n"
        graph = send_and_receive(query)

        # Frame the enumerable results as docs
        expanded = JSON::LD::API.fromRDF(graph)
        raise "No configured JSON-LD frame" unless blacklight_config.frame
        framed = JSON::LD::API.frame(expanded, blacklight_config.frame)
        framed['@graph']
      elsif params.fetch(:rows, 10) > 0 && count > 0
        query = prefixes + index_query +
          where + "}\n" +
          "LIMIT #{params.fetch(:rows, 10).to_i}\n"
        query += "OFFSET #{params[:start]}" if params[:start].to_i > 0

        # FIXME: ordering

        ids = send_and_receive(query).map(&:id)

        # FIXME: if we used a sub-select, this could be done in a single query
        # Get back constructed entities as a frame
        query = prefixes + construct + where +
        "  FILTER(?id IN(#{ids.map(&:to_ntriples).join(',')}))\n}\n"
        graph = send_and_receive(query)

        # Frame the enumerable results as docs
        expanded = JSON::LD::API.fromRDF(graph)
        raise "No configured JSON-LD frame" unless blacklight_config.frame
        framed = JSON::LD::API.frame(expanded, blacklight_config.frame)
        framed['@graph']
      else
        []
      end
      raise "No framed results" unless docs

      # Get facet fields
      facet_fields = HashWithIndifferentAccess.new
      params.fetch(:facets, {}).each do |name, facet|
        var_sym = facet[:variable].to_s[1..-1].to_sym
        query = prefixes + "\nSELECT #{facet[:variable]} (COUNT(*) as ?__count__)" +
          where + "}\n" +
          "GROUP BY #{facet[:variable]}\n"
        query += "OFFSET #{facet[:offset].to_i}\n" if facet[:offset]
        query += "LIMIT #{facet[:limit].to_i}\n" if facet[:limit]

        # Order by variable our count
        query += if facet[:sort] == 'count'
          "ORDER BY __count__\n"
        else
          "ORDER BY #{facet[:variable]}\n"
        end

        # FIXME: consider facet prefixes for SPARQL

        # Facet field values as Hash
        facet_fields[name] = send_and_receive(query).inject({}) do |memo, soln|
          memo.merge(soln[var_sym].object => soln[:__count__].object)
        end
      end

      facet_counts = HashWithIndifferentAccess.new
      # FIXME: where would facet_queries come from?
      facet_counts[:facet_fields] = facet_fields

      response_opts = {
        facet_counts: facet_counts,
        numFound: count,
        document_model: blacklight_config.document_model,
        blacklight_config: blacklight_config
      }.with_indifferent_access
      blacklight_config.response_model.new(docs, params, response_opts)
    end

    ##
    # Execute a SPARQL query returning `RDF::Query::Solutions`
    #
    # @param [String] :query
    #   SPARQL query should return result set. Query string can be parameterized
    #   with arguments in `params` interpolated using `String#%`.
    # @return [RDF::Query::Solutions, RDF::Enumerable] the SPARQL response object
    def send_and_receive(query)
      benchmark("SPARQL fetch", level: :debug) do
        # Query endpoint, interpolating parameters
        sparql_response = connection.query(query)

        Blacklight.logger.debug {"SPARQL query: #{query}"}
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
        if connection_config[:repository]
          # Create a new repository to use as client
          case repo_config = connection_config[:repository]
          when /sqlite3|postgres/
            require 'rdf/do'
            require 'do_sqlite3' if repo_config.include?("sqlite3")
            require 'do_postgres' if repo_config.include?("postgres")

            # Open a local repository and use as a SPARQL client
            SPARQL::Client.new RDF::DataObjects::Repository.new(repo_config)
          when /mongo/
            require 'rdf/mongo'
            SPARQL::Client.new RDF::Mongo::Repository.new(connection_config)
          else
          end
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