require 'rails_helper'

describe Blacklight::Sparql::Repository do

  let :blacklight_config do
    CatalogController.blacklight_config.deep_copy
  end

  subject do
    Blacklight::Sparql::Repository.new blacklight_config
  end

  let :mock_response do
    { response: { docs: [document]}}
  end

  let :document do
    {}
  end

  describe "#find" do
    it "returns the entity description for a given IRI" do
      expect(subject.find("http://nomisma.org/id/-des_cos")).to be_a?(Blacklight::Sparql::Document)
    end
  end

  describe "#search" do
    it "should use the search-specific solr path"

    it "should use the default solr path"

    it "should use a default :qt param"

    it "should use the provided :qt param"
    
    it "should preserve the class of the incoming params"
  end

  describe "#send_and_receive" do
    describe "http_method configuration" do
      describe "using default" do

        it "defaults to get"
      end

      describe "setting to post"
    end
  end

  describe "http_method configuration", integration: true do
    let (:blacklight_config) {config = Blacklight::Configuration.new; config.http_method=:post; config}

    it "should send a post request to solr and get a response back"
  end
end
