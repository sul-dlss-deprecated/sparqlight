# frozen_string_literal: true
require 'rails/generators'

module Blacklight::Sparql
  class DocumentGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../templates', __FILE__)

    argument     :model_name, :type => :string , :default => "sparql_document"

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Creates a blacklight document in your /app/models directory
    EOS

    def create_sparql_document
      template "sparql_document.rb", "app/models/#{model_name}.rb"
    end

  end
end
