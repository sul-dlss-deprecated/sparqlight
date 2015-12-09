require 'rails_helper'

describe Blacklight::Sparql::Repository do

  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  subject do
    Blacklight::Sparql::Repository.new blacklight_config
  end

  let :mock_response do
    [RDF::Query::Solution.new]
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
      search_params[:query] = "query"
      allow(subject.connection).to receive(:query).with(anything).and_return(mock_response)
      
      response = subject.search(search_params)
      expect(response).to be_a_kind_of Blacklight::Sparql::Response
      expect(response.params).to be_a_kind_of HashWithIndifferentAccess
    end
  end

  describe "#find", integration: true do
    it "returns the entity description for a given IRI" do
      result = subject.find("http://nomisma.org/id/10-as")
      expect(result).to be_a(Blacklight::Sparql::Response)
      expect(result.documents.length).to eql 1
    end
  end
end
