# README

## General Approach

* `catalog_controller` is reduced, and creates configurations such as the following:

  ```
    config.repository_class     = Blacklight::Sparql::Repository
    config.search_builder_class = ::SearchBuilder
    config.document_model       = ::SparqlDocument
    config.response_model       = Blacklight::Sparql::Response
  ```

* `SparqlRepository` is based on `Blacklight::AbstractRepository`
  * Returns a Concise Bounded Description of the document denoted by an IRI
  * Executes a SPARQL query against the endpoint, returning a result set
* `SparqlBuilder`
## Setup

* bundle install
* rake db:migrate
* rake db:seed
