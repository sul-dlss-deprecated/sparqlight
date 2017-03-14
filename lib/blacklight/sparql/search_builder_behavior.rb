module Blacklight::Sparql
  module SearchBuilderBehavior
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain = [
        :add_query_to_sparql, :add_facet_fq_to_sparql,
        :add_facetting_to_sparql, :add_sparql_fields_to_query, :add_paging_to_sparql,
        :add_sorting_to_sparql, :add_group_config_to_sparql,
        :add_facet_paging_to_sparql
      ]
    end

    ##
    # Take the user-entered query, and put it in the SPARQL params,
    # including config's "search field" params for current search field.
    def add_query_to_sparql sparql_parameters
      if field = search_field || blacklight_config.default_search_field
        search_def = {
          variable: field.variable,
          patterns: field.patterns
        }

        if blacklight_params[:q].is_a? Hash
          q = blacklight_params[:q]
          raise "FIXME, translation of Solr search for SPARQL"
        elsif blacklight_params[:q]
          # Create search field with variable, pattern and :q
          search_def.merge!(q: blacklight_params[:q])
          sparql_parameters[:search] = search_def
        end
      end
    end

    ##
    # Add any existing facet limits, stored in app-level HTTP query
    # to Sparql
    def add_facet_fq_to_sparql sparql_parameters

      # convert a String value into an Array
      if sparql_parameters[:fq].is_a? String
        sparql_parameters[:fq] = [sparql_parameters[:fq]]
      end

      # :fq, map from :f.
      if ( blacklight_params[:f])
        f_request_params = blacklight_params[:f]

        f_request_params.each_pair do |facet_field, value_list|
          next unless facet = blacklight_config.facet_fields[facet_field.to_s]
          sparql_parameters[:facet_values] ||= {}
          case Array(value_list).length
          when 0
          when 1
            v = Array(value_list).first
            sparql_parameters[:facet_values][facet.variable] = v unless v.to_s.empty?
          else
            sparql_parameters[:facet_values][facet.variable] = value_list
          end
        end
      end
    end

    ##
    # Add appropriate SPARQL facetting filters.
    def add_facetting_to_sparql sparql_parameters
      facet_fields_to_include_in_request.each do |field_name, facet|
        sparql_parameters[:facets] ||= {}
        facet_param = {variable: facet.variable}

        facet_param[:sort] = facet.sort if facet.sort

        # Support facet paging and 'more'
        # links, by sending a facet.limit one more than what we
        # want to page at, according to configured facet limits.
        facet_param[:limit] = (facet_limit_for(field_name) + 1) if facet_limit_for(field_name)

        sparql_parameters[:facets][field_name] = facet_param
      end
    end

    def add_sparql_fields_to_query sparql_parameters
      fields = blacklight_config.show_fields.select(&method(:should_add_field_to_request?))

      blacklight_config.index_fields.select(&method(:should_add_field_to_request?)).each do |key, field|
        fields[key] || field
      end
      sparql_parameters[:fields] = fields.values
    end

    ###
    # copy paging params from BL app over to SPARQL, changing
    # app level per_page and page to Solr rows and start.
    def add_paging_to_sparql sparql_parameters
      rows(sparql_parameters[:rows] || 10) if rows.nil?

      sparql_parameters[:rows] = rows
      sparql_parameters[:start] = start if start != 0
    end

    ###
    # copy sorting params from BL app over to solr
    def add_sorting_to_sparql sparql_parameters
      sparql_parameters[:sort] = sort unless sort.blank?
    end

    # Remove the group parameter if we've faceted on the group field (e.g. for the full results for a group)
    def add_group_config_to_sparql sparql_parameters
      if blacklight_params[:f] && blacklight_params[:f][blacklight_config.index.group]
        sparql_parameters[:group] = false
      end
    end

    def add_facet_paging_to_sparql sparql_parameters
      return unless facet.present?

      facet_config = blacklight_config.facet_fields[facet]

      # Now override with our specific things for fetching facet values
      sparql_parameters[:facets] ||= {}
      sparql_parameters[:facets][facet_config.field] ||= {variable: facet_config.variable}
      facet_param = sparql_parameters[:facets][facet_config.field]

      limit = if scope.respond_to?(:facet_list_limit)
                scope.facet_list_limit.to_s.to_i
              elsif sparql_parameters["facet.limit"]
                sparql_parameters["facet.limit"].to_i
              else
                20
              end

      page = blacklight_params.fetch(request_keys[:page], 1).to_i
      offset = (page - 1) * (limit)

      sort = blacklight_params[request_keys[:sort]]
      prefix = blacklight_params[request_keys[:prefix]]

      # Need to set as f.facet_field.facet.*  to make sure we
      # override any field-specific default in the solr request handler.
      facet_param[:limit]  = limit
      facet_param[:offset] = offset
      facet_param[:sort]   = sort if blacklight_params[request_keys[:sort]]
      facet_param[:prefix] = prefix if blacklight_params[request_keys[:prefix]]

      sparql_parameters[:rows] = 0
    end

    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is avaialble, returns nil. Used from #add_facetting_to_sparql
    # to supply f.fieldname.facet.limit values in solr request (no @response
    # available), and used in display (with @response available) to create
    # a facet paginator with the right limit.
    def facet_limit_for(facet_field)
      facet = blacklight_config.facet_fields[facet_field]
      return if facet.blank?

      if facet.limit
        facet.limit == true ? blacklight_config.default_facet_limit : facet.limit
      end
    end

    # FIXME: we should create an alias of add_facet_fields_to_solr_request to add_facet_fields_to_sparql_request
    def facet_fields_to_include_in_request
      blacklight_config.facet_fields.select do |field_name,facet|
        facet.include_in_request || (facet.include_in_request.nil? && blacklight_config.add_facet_fields_to_solr_request)
      end
    end

    def request_keys
      blacklight_config.facet_paginator_class.request_keys
    end
  end
end