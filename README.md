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
* bundle exec rake db:migrate
* bundle exec rake db:seed

Tests can be run using `rspec`

Service can be run locally using `bundle exec rails server`

### Running on Blazegraph

* `brew install blazegraph`

Follow steps to have MongoDB start on login and run `lanuchctl` to start immediately (details may vary):

    sudo cp -fv /usr/local/opt/bigdata/*.plist /Library/LaunchDaemons
    sudo chown root /Library/LaunchDaemons/homebrew.mxcl.bigdata.plist

Then to load bigdata now:

    sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.bigdata.plist

Or, if you don't want/need launchctl, you can just run:

    bigdata start

Load data using the blazegraph UI at `http://localhost:9999/bigdata/#update`. Drag `etc/nomisma-full.ttl` into update window and select `Update` control.

Subsequently, perform rails initialization:

* bundle install
* RAILS_ENV=production bundle exec rake db:migrate
* RAILS_ENV=production bundle exec rake db:seed

After initializing secrets in config/secrets.yml, run the server in production mode pointing to the BlazeGraph SPARQL endpoint:

    SPARQL_URL=http://localhost:9999/bigdata/sparql RAILS_ENV=production bundle exec rails server