require 'ostruct'

module Blacklight::Sparql::Response::Facets
  # represents a facet value; which is a field value and its hit count
  class FacetItem < OpenStruct
    def initialize *args
      options = args.extract_options!

      # Backwards-compat method signature
      value = args.shift
      hits = args.shift

      options[:value] = value if value
      options[:hits] = hits if hits

      super(options)
    end

    def label
      super || value
    end

    def as_json(props = nil)
      table.as_json(props)
    end
  end

  # represents a facet; which is a field and its values
  class FacetField
    attr_reader :name, :items
    def initialize name, items, options = {}
      @name = name
      @items = items
      @options = options
    end

    def limit
      @options[:limit] || sparql_default_limit
    end

    def sort
      @options[:sort] || sparql_default_sort
    end

    def offset
      @options[:offset] || sparql_default_offset
    end

    def prefix
      @options[:prefix] || sparql_default_prefix
    end

    def index?
      sort == 'index'
    end

    def count?
      sort == 'count'
    end

    private
    def sparql_default_limit
      100
    end

    def sparql_default_sort
      if limit > 0
        'count'
      else
        'index'
      end
    end

    def sparql_default_offset
      0
    end

    def sparql_default_prefix
      nil
    end
  end

  ##
  # Get all the Sparql facet data (fields right now) as a hash
  def aggregations
    @aggregations ||= {}.merge(facet_field_aggregations)
  end

  def facet_counts
    @facet_counts ||= self['facet_counts'] || {}
  end

  # Returns the hash of all the facet_fields (ie: {'instock_b' => ['true', 123, 'false', 20]}
  def facet_fields
    @facet_fields ||= begin
      facet_counts['facet_fields'] || {}
    end
  end

  private
  ##
  # Convert facet_field response into
  # a hash of FacetField objects
  def facet_field_aggregations
    facet_fields.each_with_object({}) do |(facet_field_name, values), hash|
      items = values.map do |value, hits|
        FacetItem.new(value: value, hits: hits)
      end

      options = facet_field_aggregation_options(facet_field_name)
      hash[facet_field_name] = FacetField.new(facet_field_name,
                                              items,
                                              options)

      if blacklight_config and !blacklight_config.facet_fields[facet_field_name]
        # alias all the possible blacklight config names..
        blacklight_config.facet_fields.select { |k,v| v.field == facet_field_name }.each do |key,_|
          hash[key] = hash[facet_field_name]
        end
      end
    end
  end

  def facet_field_aggregation_options(facet_field_name)
    options = {}
    facet_info = params[:facets].fetch(facet_field_name, {})
    options[:sort] = facet_info[:sort] || params[:'facet.sort']
    if facet_info[:limit] || params[:"facet.limit"]
      options[:limit] = (facet_info[:limit] || params[:"facet.limit"]).to_i
    end

    if facet_info[:offset] || params[:"facet.offset"]
      options[:offset] = (facet_info[:offset] || params[:"facet.offset"]).to_i
    end

    if facet_info[:prefix] || params[:"facet.prefix"]
      options[:prefix] = (facet_info[:prefix] || params[:"facet.prefix"])
    end
    options
  end
end # end Facets
