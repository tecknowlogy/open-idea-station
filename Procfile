web: bundle exec rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -q default -q mailers -q urgent,2