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

### Running on Blazegraph - for macOS

* `brew install blazegraph`

Follow steps to have MongoDB start on login and run `lanuchctl` to start immediately (details may vary):

    sudo cp -fv /usr/local/opt/bigdata/*.plist /Library/LaunchDaemons
    sudo chown root /Library/LaunchDaemons/homebrew.mxcl.bigdata.plist

Then to load bigdata now:

    sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.bigdata.plist

Or, if you don't want/need launchctl, you can just run:

    bigdata start

Load data using the blazegraph UI at `http://localhost:9999/bigdata/#update`. Browse the file system to select `db/nomisma-full.ttl` and select `Update` control.

Subsequently, perform rails initialization:

* bundle install
* RAILS_ENV=production bundle exec rake db:migrate
* RAILS_ENV=production bundle exec rake db:seed

After initializing secrets in config/secrets.yml, run the server in production mode pointing to the BlazeGraph SPARQL endpoint:

    SPARQL_URL=http://localhost:9999/bigdata/sparql RAILS_ENV=production bundle exec rails server

### Running on Blazegraph - for Debian/Ubuntu

Blazegraph installation instructions are at
* https://github.com/blazegraph/database/tree/master/blazegraph-deb
* once installed, try `sudo service blazegraph start`

MongoDB installation instructions are at
* https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
* once installed, try `sudo service mongodb start`

Create a new blazegraph namespace, say `sparqlite`, using the defaults for
a `triples` KB, and select 'use' it.  Load data using the blazegraph UI at
* http://localhost:9999/blazegraph/#update

Browse to `db/nomisma-full.ttl` and select `Update`.  Once the data is loaded
into blazegraph, return to the sparqlite console to perform rails initialization:

* bundle install
* RAILS_ENV=production bundle exec rake db:migrate
* RAILS_ENV=production bundle exec rake db:seed
* RAILS_ENV=production bundle exec rake secrets
* Add that value to `config/secrets.yml`

Run the server in production mode pointing to the BlazeGraph SPARQL endpoint:

    SPARQL_URL=http://localhost:9999/blazegraph/namespace/sparqlite/sparql RAILS_ENV=production bundle exec rails server

