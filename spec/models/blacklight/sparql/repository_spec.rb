require 'rails_helper'

describe Blacklight::Sparql::Repository do

  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  subject do
    Blacklight::Sparql::Repository.new blacklight_config
  end

  let :mock_response do
    RDF::Graph.new do |g|
      g << RDF::Statement(RDF::URI("http://example/123"), RDF.type, RDF::URI("http://nomisma.org/ontology#Denomination"))
    end
  end

  let :mock_index do
    [RDF::Query::Solution.new(:id => RDF::URI("http://example/123"))]
  end

  let :mock_count do
    [RDF::Query::Solution.new(:__count__ => 1)]
  end

  let :document do
    {}
  end

  describe "#find" do
    it "should preserve the class of the incoming params" do
      doc_params = HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:query).with(anything).and_return(mock_response)
      response = subject.find("http://example/123", doc_params)
      expect(response).to be_a_kind_of Blacklight::Sparql::Response
      expect(response.params).to be_a_kind_of HashWithIndifferentAccess
    end
  end

  describe "#search" do
    it "should preserve the class of the incoming params" do
      search_params = HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:query).and_return(mock_response)

      response = subject.search(search_params)
      expect(response).to be_a_kind_of Blacklight::Sparql::Response
      expect(response.params).to be_a_kind_of HashWithIndifferentAccess
    end

    it "should search variable" do
      search_params = {search: {variable: "?lit", q: "foo"}}.with_indifferent_access
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/FILTER\(CONTAINS\(\?lit, 'foo'\)\)/)

      subject.search(search_params)
    end

    it "should not search variable with empty value" do
      search_params = {search: {variable: "?lit", q: ""}}.with_indifferent_access
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).not_to receive(:query).with(/FILTER\(CONTAINS\(\?lit, ''\)\)/)

      subject.search(search_params)
    end

    it "should search multiple variables" do
      search_params = {search: {variable: %w(?a ?b), q: "foo"}}.with_indifferent_access
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/FILTER\(CONTAINS\(COALESCE\(\?a,\?b\), 'foo'\)\)/)

      subject.search(search_params)
    end

    it "should search with a bound facet value" do
      search_params = HashWithIndifferentAccess.new
      search_params[:facet_values] = {"?lit" => "foo"}
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/FILTER\(STR\(\?lit\) = 'foo'\)/)

      subject.search(search_params)
    end

    it "should search with a bound facet values (multiple values for facet)" do
      search_params = HashWithIndifferentAccess.new
      search_params[:facet_values] = {"?lit" => %w(foo bar)}
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/FILTER\(STR\(\?lit\) IN\('foo', 'bar'\)\)/)

      subject.search(search_params)
    end

    it "should request a count" do
      search_params = HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/SELECT \(COUNT\(\?id\) as \?__count__\)/)

      subject.search(search_params)
    end

    it "should get distinct ?id" do
      search_params = HashWithIndifferentAccess.new
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/SELECT \(COUNT\(\?id\) as \?__count__\)/).and_return(mock_count)
      expect(subject.connection).to receive(:query).with(/SELECT DISTINCT \?id/).and_return(mock_index)

      subject.search(search_params)
    end

    it "should request ids with offset" do
      search_params = HashWithIndifferentAccess.new
      search_params[:start] = 5
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/SELECT \(COUNT\(\?id\) as \?__count__\)/).and_return(mock_count)
      expect(subject.connection).to receive(:query).with(/SELECT DISTINCT \?id.*OFFSET 5/m).and_return(mock_index)

      subject.search(search_params)
    end

    it "should request ids with limit" do
      search_params = HashWithIndifferentAccess.new
      search_params[:rows] = 5
      allow(subject.connection).to receive(:query).and_return(mock_response)
      expect(subject.connection).to receive(:query).with(/SELECT \(COUNT\(\?id\) as \?__count__\)/).and_return(mock_count)
      expect(subject.connection).to receive(:query).with(/SELECT DISTINCT \?id.*LIMIT 5/m).and_return(mock_index)

      subject.search(search_params)
    end

    it "should request facet counts" do
      search_params = HashWithIndifferentAccess.new
      search_params[:rows] = 0
      search_params[:facets] = {"var" => {:variable => "?var"}}
      expect(subject.connection).to receive(:query).with(/SELECT \?var \(COUNT\(\*\) as \?__count__\)/).and_return([])

      subject.search(search_params)
    end
  end

  context "integration", integration: true do
    describe "#find" do
      it "returns the entity description for a given IRI" do
        result = subject.find("http://nomisma.org/id/10-as")
        expect(result).to be_a(Blacklight::Sparql::Response)
        expect(result.documents.length).to eql 1
      end
    end

    describe "#search" do
      let(:response) do
        Blacklight::Sparql::Repository.new(blacklight_config).
          search(:facets => {"num_label" => {:variable => "?num_lab"}})
      end
      subject {response}

      its(:total) {is_expected.to eql 14}
      its(:start) {is_expected.to eql 0}

      its(:docs) {is_expected.to all(be_a Blacklight::Sparql::Document)}

      it "should have expected facets" do
        expect(response[:facet_counts]).to eq({
          "facet_fields" => {
            "num_label" => {
              "Greek Numismatics" => 12,
              "Roman Numismatics" => 2
            }
          }
        })
      end
    end
  end
end
