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

On a Mac, install [Homebrew](http://brew.sh).

Using Homebrew, install MongoDB:

* `brew install mongodb`

Follow steps to have MongoDB start on login and run `lanuchctl` to start immediately (details may vary):

* `ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents`
* `launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist`

Subsequently, perform rails initialization:

* bundle install
* rake db:migrate
* rake db:seed

Tests can be run using `rspec`

Service can be run locally using `bundle exec rails server`
