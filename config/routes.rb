Rails.application.routes.draw do

  root to: 'catalog#index'

  mount Blacklight::Engine => '/'

  concern :exportable, Blacklight::Routes::Exportable.new
  concern :searchable, Blacklight::Routes::Searchable.new

  constraints id: /.+/ do
    resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
      concerns :searchable
    end

    resources :sparql_documents, only: [:show], path: '/catalog', controller: 'catalog' do
      concerns :exportable
    end

    resources :bookmarks do
      concerns :exportable

      collection do
        delete 'clear'
      end
    end
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
