# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "@hotwired--turbo-rails.js" # @8.0.16
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.0.200
# pin_all_from "app/javascript/channels", under: "channels"
pin "@hotwired/turbo", to: "@hotwired--turbo.js" # @8.0.13
pin "@rails/actioncable/src", to: "@rails--actioncable--src.js" # @8.0.200
pin "fighter_features", to: "fighter_features.js"
