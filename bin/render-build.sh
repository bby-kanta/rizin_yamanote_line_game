#!/usr/bin/env bash
# exit on error  
set -o errexit

bundle install
bundle exec rake assets:precompile

rm -f db/schema.rb

# Run migrations
bundle exec rake db:migrate RAILS_ENV=production || {
  echo "Some migrations may have failed. Attempting to continue..."
  bundle exec rake db:migrate:status RAILS_ENV=production || true
}
