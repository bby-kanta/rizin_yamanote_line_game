#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile

# Check if migrations are needed and run them
bundle exec rake db:migrate:status || true
bundle exec rake db:migrate || true
