source 'https://rubygems.org'
ruby '2.1.6'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.1'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'haml-rails'

gem 'angularjs-rails'
gem 'angular_rails_csrf'
gem 'angular-ui-bootstrap-rails'
gem 'bootstrap-select-rails'
gem 'sass-rails', '~> 5.0'
gem 'bootstrap-sass'
gem 'font-awesome-rails'

# for donut chart on landing page
gem 'd3_rails'

# for Map on landing page
gem 'mapbox-rails'

# Socrata Ruby library
gem 'soda-ruby', :require => 'soda'

# For configuration security
gem 'figaro'

gem 'newrelic_rpm'

group :test do
  gem 'rubocop-rspec'
  gem 'simplecov', require: false
  gem "codeclimate-test-reporter", require: nil
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rack-mini-profiler'
  gem 'sqlite3'
end

group :production do
  gem 'heroku-deflater'
  gem 'pg'
  gem 'rails_12factor'
  gem 'redis'
  gem 'redis-rails'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'rubocop', require: false
  gem 'pry-rails'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'

  gem 'jasmine-jquery-rails'
  gem 'phantomjs'
  gem "teaspoon-jasmine"
end
