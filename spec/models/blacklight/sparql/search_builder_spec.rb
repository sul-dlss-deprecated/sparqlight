require 'rails_helper'

describe Blacklight::Sparql::SearchBuilderBehavior do
  let(:single_facet) { { format: 'Book' } }
  let(:multi_facets) { { format: 'Book', language_facet: 'Tibetan' } }
  let(:mult_word_query) { 'tibetan history' }
  let(:subject_search_params) { { commit: "search", search_field: "subject", action: "index", controller: "catalog", rows: "10", q: "wome" } }

  let(:blacklight_config) { CatalogController.blacklight_config.deep_copy }
  let(:user_params) { Hash.new }
  let(:context) { CatalogController.new }

  before { allow(context).to receive(:blacklight_config).and_return(blacklight_config) }

  let(:search_builder_class) do
    Class.new(Blacklight::SearchBuilder) do
      include Blacklight::Sparql::SearchBuilderBehavior
    end
  end
  let(:search_builder) { search_builder_class.new(context) }

  subject { search_builder.with(user_params) }

  context "with default processor chain" do
    context "with two arguments" do
      subject do
        Deprecation.silence Blacklight::SearchBuilder do
          search_builder_class.new true, context
        end
      end
      it "uses the class-level default_processor_chain" do
        expect(subject.processor_chain).to eq search_builder_class.default_processor_chain
      end
    end

    context "with one arguments" do
      subject { search_builder }
      it "uses the class-level default_processor_chain" do
        expect(subject.processor_chain).to eq search_builder_class.default_processor_chain
      end
    end
  end

  context "with a complex parameter environment" do
    subject { search_builder.with(user_params).processed_parameters }

    let(:user_params) do
      {search_field: "test_field", q: "test query", "facet.field" => "extra_facet"}
    end

    let(:blacklight_config) do
      Blacklight::Configuration.new.tap do |config|
        config.add_search_field "test_field", label: "Test", variable: "?test"
      end
    end
    it "should set search from search_field definition" do
      expect(subject[:search]).to eq({"variable" => "?test", "patterns" => nil, "q" => "test query"})
    end

    describe "should respect proper precedence of settings, " do
      it "should not put :search_field in produced params" do
        expect(subject[:search_field]).to be_nil
      end

      it "should add in extra facet.field from params", skip: "Does this make sense for SPARQL; facets need to be configured" do
        expect(subject[:"facet.field"]).to include("extra_facet")
      end
    end
  end

  # SPECS for actual search parameter generation
  describe "#processed_parameters" do

    subject do
      search_builder.with(user_params).processed_parameters
    end

    context "when search_params_logic is customized", skip: "This doesn't seem relevant for SPARQL, as it's BL logic" do
      let(:search_builder) { search_builder_class.new(method_chain, context) }
      let(:method_chain) { [:add_foo_to_sparql_params] }

      it "allows customization of search_params_logic" do
          allow(search_builder).to receive(:add_foo_to_sparql_params) do |sparql_params, user_params|
            sparql_params[:wt] = "TESTING"
          end

          expect(subject[:wt]).to eq "TESTING"
      end
    end

    context "facet paging" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field 'subject_topic_facet',
            label: 'Topic',
            variable: "?topic",
            limit: 20,
            index_range: 'A'..'Z'
          config.add_facet_fields_to_solr_request!
        end
      end

      it "should have ?topic facet" do
        expect(subject[:facets]).to have_key("?topic")
        expect(subject[:facets]).to be_a(Hash)
      end

      it "should generate a facet limit" do
        expect(subject.fetch(:facets, {}).fetch("?topic", {})).to include(limit: 21)
      end

      it "should handle no facet_limits in config" do
        blacklight_config.facet_fields = {}
        expect(subject.fetch(:facets, {}).fetch("?topic", {})).not_to include(limit: 21)
      end
    end


    describe "with max per page enforced" do
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.max_per_page = 123
        end
      end

      let(:user_params) { { per_page: 98765 } }
      it "should enforce max_per_page against all parameters" do
        expect(blacklight_config.max_per_page).to eq 123
        expect(subject[:rows]).to eq 123
      end
    end

    describe 'for an entirely empty search' do

      it 'should not have a search param' do
        expect(subject[:search]).to be_nil
      end
      it 'should have default rows' do
        expect(subject[:rows]).to eq 10
      end
      it 'should have default facet fields' do
        expect(subject[:facets]).to eq("?num_lab" => {"variable" => "?num_lab"})
      end
      it "should have no facet_values" do
        expect(subject[:facet_values]).to be_blank
      end
    end

    describe "for an empty string search" do
      let(:user_params) { { q: "" } }
      it "should return empty string search in sparql parameters" do
        expect(subject[:search]).to include("variable", "patterns", "q")
        expect(subject[:search]["variable"]).to match_array(%w(?lab ?defn ?num_lab))
        expect(subject[:search]["q"]).to eql ""
      end
    end

    describe "for request params also passed in as argument" do
      let(:user_params) { { q: "some query", 'q' => 'another value' } }
      it "should only have one value for the key 'q' regardless if a symbol or string" do
        expect(subject[:search]).to be_a(Hash)
        expect(subject[:search][:q]).to eq 'some query'
        expect(subject['search']['q']).to eq 'some query'
      end
    end


    describe "for one facet, no query" do
      let(:user_params) { { f: single_facet } }
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field 'format',
            label:    'Format',
            variable: "?format"
        end
      end
      it "should have proper sparql parameters" do

        expect(subject[:search]).to be_blank

        single_facet.each_value do |value|
          expect(subject[:facet_values]).to include("?format" => "Book")
        end
      end
    end

    describe "for an empty facet limit param" do
      let(:user_params) { { f: { "format" => [""] } } }
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field 'format',
            label:    'Format',
            variable: "?format"
        end
      end
      it "should not add any facet_values to sparql" do
        expect(subject[:facet_values]).to be_blank
      end
    end

    describe "with Multi Facets, No Query" do
      let(:user_params) { { f: multi_facets } }
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field 'format', label: 'Format', variable: "?format"
          config.add_facet_field 'language_facet', label: "Language", variable: "?language"
        end
      end
      it 'should have facet_values set properly' do
        expect(subject[:facet_values]).to include("?format" => "Book")
        expect(subject[:facet_values]).to include("?language" => "Tibetan")
      end
    end

    describe "with Multi Facets, Multi Word Query" do
      let(:user_params) { { q: mult_word_query, f: multi_facets } }
      let(:blacklight_config) do
        Blacklight::Configuration.new.tap do |config|
          config.add_facet_field 'format', label: 'Format', variable: "?format"
          config.add_facet_field 'language_facet', label: "Language", variable: "?language"
          config.add_search_field 'all_fields', variable: %w(?format ?language)
        end
      end
      it 'should have fq and q set properly' do
        expect(subject[:facet_values]).to include("?format" => "Book")
        expect(subject[:facet_values]).to include("?language" => "Tibetan")
        expect(subject[:search]).to eq({"variable"=>["?format","?language"], "patterns"=>nil, "q"=>"tibetan history"})
      end
    end


    describe "sparql parameters for a field search from config (subject)" do
      let(:user_params) { subject_search_params }

      it "should not include weird keys not in field definition" do
        expect(subject[:phrase_filters]).to be_nil
        expect(subject[:fq]).to eq []
        expect(subject[:commit]).to be_nil
        expect(subject[:action]).to be_nil
        expect(subject[:controller]).to be_nil
      end

      it "should include proper 'search'" do
        expect(subject[:search]).to include("variable" => ["?lab", "?defn", "?num_lab"])
        expect(subject[:search]).to include("q"=>"wome")
      end
    end

    describe "sorting" do
      it "should send the default sort parameter to sparql" do
        expect(subject[:sort]).to eq "?lab asc"
      end

      it "should not send a sort parameter to sparql if the sort value is blank" do
        blacklight_config.sort_fields = {}
        blacklight_config.add_sort_field('', label: 'test')

        expect(subject).not_to have_key(:sort)
      end

      context "when the user provides sort parmeters" do
        let(:user_params) { { sort: 'sparql_test_field desc' } }
        it "passes them through" do
          expect(subject[:sort]).to eq 'sparql_test_field desc'
        end
      end
    end

    describe "mapping facet.field", skip: "Doesn't make sense for SPARQL" do
      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'some_field'
          config.add_facet_fields_to_solr_request!
        end
      end

      context "user provides a single facet.field" do
        let(:user_params) { { "facet.field" => "additional_facet" } }
        it "adds the field" do
          expect(subject[:"facet.field"]).to include("additional_facet")
          expect(subject[:"facet.field"]).to have(2).fields
        end
      end

      context "user provides a multiple facet.field" do
        let(:user_params) { { "facet.field" => ["add_facet1", "add_facet2"] } }
        it "adds the fields" do
          expect(subject[:"facet.field"]).to include("add_facet1")
          expect(subject[:"facet.field"]).to include("add_facet2")
          expect(subject[:"facet.field"]).to have(3).fields
        end
      end

      context "user provides a multiple facets" do
        let(:user_params) { { "facets" => ["add_facet1", "add_facet2"] } }
        it "adds the fields" do
          expect(subject[:"facet.field"]).to include("add_facet1")
          expect(subject[:"facet.field"]).to include("add_facet2")
          expect(subject[:"facet.field"]).to have(3).fields
        end
      end
    end
  end

  
  describe "#add_sparql_fields_to_query" do
    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_index_field 'an_index_field', variable: "?index"
        config.add_show_field 'a_show_field', variable: "?show"
        config.add_field_configuration_to_solr_request!
      end
    end

    let(:sparql_parameters) do
      sparql_parameters = Blacklight::Sparql::Request.new

      subject.add_sparql_fields_to_query(sparql_parameters)

      sparql_parameters
    end

    it "should add any extra sparql parameters from index and show fields", pending: "should include both fields, but odd config problems" do
      expect(sparql_parameters).to include("fields")
      expect(sparql_parameters[:fields].map(&:variable)).to match_array(%w(?index ?show))
    end
  end

  describe "#add_facetting_to_sparql" do

    let(:blacklight_config) do
       Blacklight::Configuration.new do |config|
         config.add_facet_field 'test_field', sort: 'count', variable: "?test"
         #config.add_facet_field 'some-query', :query => {'x' => {:fq => 'some:query' }}, :ex => 'xyz'
         config.add_facet_field 'some-field', variable: "?some"
         config.add_facet_fields_to_solr_request!
       end
    end

    let(:sparql_parameters) do
      sparql_parameters = Blacklight::Sparql::Request.new
      
      subject.add_facetting_to_sparql(sparql_parameters)

      sparql_parameters
    end

    it "should add plain parameters" do
      expect(sparql_parameters[:facets]).to include({"?test" => {"variable" => "?test", "sort" => "count"}})
    end

    it "should add sort parameters" do
      expect(sparql_parameters[:facets]).to include({"?some" => {"variable" => "?some"}})
    end

    it "should add facet exclusions", skip: "Not for SPARQL" do
      expect(sparql_parameters[:'facet.query']).to include('{!ex=xyz}some:query')
      expect(sparql_parameters[:'facet.pivot']).to include('{!ex=xyz}a,b')
    end

    it "should add any additional sparql_params", skip: "Not for SPARQL" do
      expect(sparql_parameters[:'f.some-field.facet.mincount']).to eq 15
    end

    describe ":include_in_request" do
      let(:sparql_parameters) do
        sparql_parameters = Blacklight::Sparql::Request.new
        subject.add_facetting_to_sparql(sparql_parameters)
        sparql_parameters
      end

      it "should respect the include_in_request parameter" do
        blacklight_config.add_facet_field 'yes_facet', variable: "?yes", include_in_request: true
        blacklight_config.add_facet_field 'no_facet', variable: "?no", include_in_request: false
        
        expect(sparql_parameters[:facets]).to include('?yes')
        expect(sparql_parameters[:facets]).not_to include('?no')
      end

      it "should default to including facets if add_facet_fields_to_solr_request! was called" do
        blacklight_config.add_facet_field 'yes_facet', variable: "?yes"
        blacklight_config.add_facet_field 'no_facet', variable: "?no", include_in_request: false
        blacklight_config.add_facet_fields_to_solr_request!

        expect(sparql_parameters[:facets]).to include('?yes')
        expect(sparql_parameters[:facets]).not_to include('?no')
      end
    end

    describe ":add_facet_fields_to_solr_request!" do

      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'yes_facet', variable: "?yes", include_in_request: true
          config.add_facet_field 'no_facet', variable: "?no", include_in_request: false
          config.add_facet_field 'maybe_facet', variable: "?maybe"
          config.add_facet_field 'another_facet', variable: "?another"
        end
      end

      let(:sparql_parameters) do
        sparql_parameters = Blacklight::Sparql::Request.new
        subject.add_facetting_to_sparql(sparql_parameters)
        sparql_parameters
      end

      it "should add facets to the sparql request" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(sparql_parameters[:facets]).to include('?yes')
        expect(sparql_parameters[:facets]).to include('?maybe')
        expect(sparql_parameters[:facets]).to include('?another')
      end

      it "should not override field-specific configuration by default" do
        blacklight_config.add_facet_fields_to_solr_request!
        expect(sparql_parameters[:facets]).not_to include('?no')
      end

      it "should allow white-listing facets" do
        blacklight_config.add_facet_fields_to_solr_request! 'maybe_facet'
        expect(sparql_parameters[:facets]).to include('?maybe')
        expect(sparql_parameters[:facets]).not_to include('?another')
      end

      it "should allow white-listed facets to override any field-specific include_in_request configuration" do
        blacklight_config.add_facet_fields_to_solr_request! 'no_facet'
        expect(sparql_parameters[:facets]).to include('?no')
      end
    end
  end

  describe "#add_facet_paging_to_sparql" do
    let(:facet_field) { 'format' }
    let(:sort_key) { Blacklight::Sparql::FacetPaginator.request_keys[:sort] }
    let(:page_key) { Blacklight::Sparql::FacetPaginator.request_keys[:page] }
    let(:prefix_key) { Blacklight::Sparql::FacetPaginator.request_keys[:prefix] }

    let(:blacklight_config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_fields_to_solr_request!
        config.add_facet_field 'format', variable: "?format"
        config.add_facet_field 'format_ordered', variable: "?ordered", sort: :count
        config.add_facet_field 'format_limited', variable: "?limited", limit: 5
      end
    end

    let(:sparql_parameters) do
      sparql_parameters = Blacklight::Sparql::Request.new
      subject.facet(facet_field).add_facet_paging_to_sparql(sparql_parameters)
      sparql_parameters
    end

    it 'sets rows to 0' do
      expect(sparql_parameters[:rows]).to eq 0
    end
    it 'sets facets requested to facet_field argument' do
      expect(sparql_parameters[:facets]).to include("?format")
    end
    it 'defaults offset to 0' do
      expect(sparql_parameters[:facets]["?#{facet_field}"]).to include(offset: 0)
    end
    context 'when offset is manually set' do
      let(:user_params) { { page_key => 2 } }
      it 'uses offset manually set, and converts it to an integer' do
        expect(sparql_parameters[:facets]["?#{facet_field}"]).to include(offset: 20)
      end
    end
    it 'defaults limit to 20' do
      expect(sparql_parameters[:facets]["?#{facet_field}"]).to include(limit: 20)
    end

    context 'when facet_list_limit is defined in scope', pending: "configuration problem" do
      before do
        allow(context).to receive_messages facet_list_limit: 1000
      end
      it 'uses scope method for limit' do
        expect(sparql_parameters[:facets]["?#{facet_field}"]).to include(limit: 1000)
      end

      it 'uses controller method for limit when a ordinary limit is set' do
        expect(sparql_parameters[:facets]["?#{facet_field}"]).to include(limit: 1000)
      end
    end

    it 'uses the default sort' do
      expect(sparql_parameters[:facets]["?#{facet_field}"][:sort]).to be_blank
    end

    context 'when sort is provided' do
      let(:user_params) { { sort_key => 'index' } }
      it 'uses sort provided in the parameters' do
        expect(sparql_parameters[:facets]["?#{facet_field}"]).to include("sort" => "index")
      end
    end

    context 'when a prefix is provided' do
      let(:user_params) { { prefix_key => 'A' } }
      it 'includes the prefix in the query' do
        expect(sparql_parameters[:facets]["?#{facet_field}"]).to include("prefix" => "A")
      end
    end
  end
end
