#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile

# Remove MySQL-generated schema.rb for PostgreSQL compatibility
rm -f db/schema.rb

bundle exec rake db:migrate
