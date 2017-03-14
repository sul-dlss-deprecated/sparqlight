# frozen_string_literal: true
module Blacklight::Sparql
  class Install < Rails::Generators::Base
    
    source_root File.expand_path('../templates', __FILE__)
    
    argument     :model_name  , type: :string , default: "user"
    argument     :controller_name, type: :string , default: "catalog"
    argument     :document_name, type: :string , default: "sparql_document"
    argument     :search_builder_name, type: :string , default: "search_builder"

    class_option :devise      , type: :boolean, default: false, aliases: "-d", desc: "Use Devise as authentication logic."

    desc <<-EOS
      This generator makes the following changes to your application:
       1. Generates blacklight:models
       2. Creates a number of public assets, including images, stylesheets, and javascript
       3. Injects behavior into your user application_controller.rb
       4. Adds Blacklight routes to your ./config/routes.rb

      Thank you for Installing SparqLight.
    EOS

    def bundle_install
      Bundler.with_clean_env do
        run "bundle install"
      end
    end

    # Copy all files in templates/public/ directory to public/
    # Call external generator in AssetsGenerator, so we can
    # leave that callable seperately too.
    # FIXME: Could be blacklight:assets, as there's nothing different here for SPARQL
    def copy_public_assets 
      generate "blacklight:sparql:assets"
    end
    
    def generate_blacklight_sparql_document
      generate 'blacklight:sparql:document', document_name
    end

    def generate_search_builder
      generate 'blacklight:sparql:search_builder', search_builder_name
    end

    def generate_blacklight_sparql_models
      generate 'blacklight:sparql:models'
    end

    # FIXME: Could be blacklight:user, as there's nothing different here for SPARQL
    def generate_blacklight_user

      generator_args = [model_name]
      if options[:devise]
        generator_args << "--devise #{options[:devise]}"
      end
      
      generate 'blacklight:sparql:user', generator_args.join(" ")
    end

    # FIXME: Could be blacklight:controller, as there's nothing different here for SPARQL
    def generate_controller
      generate 'blacklight:sparql:controller', controller_name
    end
    
    def add_default_catalog_route
      route("root to: \"#{controller_name}#index\"")
    end

    def add_sparqlight_configuration

      insert_into_file "config/application.rb", :after => "require 'rails/all'" do <<-EOF

        require 'blacklight/sparql'
EOF
      end
    end

    def add_sass_configuration

      insert_into_file "config/application.rb", :after => "config.assets.enabled = true" do <<EOF

      # Default SASS Configuration, check out https://github.com/rails/sass-rails for details
      config.assets.compress = !Rails.env.development?
EOF
      end
    end

    def inject_blacklight_i18n_strings
      copy_file "blacklight.en.yml", "config/locales/blacklight.en.yml"
    end

    def add_routes
      route "mount Blacklight::Engine => '/'"
    end
  end
end
