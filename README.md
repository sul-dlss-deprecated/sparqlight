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

Tests can be run using:

```sh
RAILS_ENV=test bundle exec rake db:test:prepare
RAILS_ENV=test bundle exec rake db:seed
RAILS_ENV=test bundle exec rake
```

Service can be run locally using `bundle exec rails server`


### Running on Blazegraph

#### Installing Blazegraph for macOS

* `brew install blazegraph`

Follow steps to have MongoDB start on login and run `lanuchctl` to start immediately (details may vary):

    sudo cp -fv /usr/local/opt/blazegraph/*.plist /Library/LaunchDaemons
    sudo chown root /Library/LaunchDaemons/homebrew.mxcl.blazegraph.plist

Then to load blazegraph now:

    sudo launchctl load /Library/LaunchDaemons/homebrew.mxcl.blazegraph.plist

Or, if you don't want/need launchctl, you can just run:

    blazegraph start

#### Installing Blazegraph for Debian/Ubuntu

Blazegraph installation instructions are at
* https://github.com/blazegraph/database/tree/master/blazegraph-deb
* once installed, try `sudo service blazegraph start`

MongoDB installation instructions are at
* https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/
* once installed, try `sudo service mongodb start`

### Configuring Blazegraph

#### Production

* This section provides no advice on how to install and run blazegraph for production operations concerns.
* Create a new blazegraph namespace, say `sparqlite`, using the defaults for a `triples` KB, and select 'use' it.
* Load data using the blazegraph UI at http://localhost:9999/blazegraph/#update
  * Browse to `db/nomisma-full.ttl` and select `Update`.

Once the data is loaded into blazegraph, return to the sparqlite console to perform rails initialization:

```
bundle install
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake db:seed # this is done manually above
RAILS_ENV=production bundle exec rake secrets
# Add that value to `config/secrets.yml`
```

Run the server in production mode pointing to this BlazeGraph SPARQL endpoint:

```
export SPARQL_URL=http://localhost:9999/blazegraph/namespace/sparqlite/sparql
RAILS_ENV=production bundle exec rails server
```

#### Development (demonstrations)

* Exploring the application is much faster using blazegraph
* Create a new blazegraph namespace, say `sparqlite-development`, using the defaults for a `triples` KB, and select 'use' it.
* Load data using the blazegraph UI at http://localhost:9999/blazegraph/#update
  * Browse to `db/nomisma_full.ttl` and select `Update`.  Once the data is loaded into blazegraph, return to the sparqlite console to prepare and run specs:

```
export SPARQL_URL=http://localhost:9999/blazegraph/namespace/sparqlite-development/sparql
# RAILS_ENV=development is the default
bundle exec rails s
```

#### Tests

* Create a new blazegraph namespace, say `sparqlite-test`, using the defaults for a `triples` KB, and select 'use' it.
* Load data using the blazegraph UI at http://localhost:9999/blazegraph/#update
  * Browse to `db/nomisma.ttl` and select `Update`.  Once the data is loaded into blazegraph, return to the sparqlite console to prepare and run specs:

```
export SPARQL_URL=http://localhost:9999/blazegraph/namespace/sparqlite-test/sparql
RAILS_ENV=test bundle exec rake db:test:prepare
RAILS_ENV=test bundle exec rake db:seed # may not work as expected, but manual loading is done as above
RAILS_ENV=test bundle exec rake

# To view the test data in the application:
RAILS_ENV=development bundle exec rails s
```
