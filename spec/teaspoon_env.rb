Teaspoon.configure do |config|

  config.mount_at = "/teaspoon"

  config.root = nil

  config.asset_paths = ["spec/javascripts/jasmine_specs", "spec/javascripts/stylesheets"]

  config.fixture_paths = ["spec/javascripts/fixtures"]

  config.suite do |suite|
    suite.use_framework :jasmine, "2.2.0"
    suite.matcher = "{spec/javascripts/jasmine_specs,app/assets}/**/*Spec.{js,js.coffee,coffee}"
    suite.helper = "spec_helper"
    suite.boot_partial = "boot"
    suite.body_partial = "body"
  end

  config.use_coverage = true

  config.coverage do |coverage|
    coverage.reports = ["html", "text"]
    # coverage.ignore = [%r{/lib/ruby/gems/}, %r{/vendor/assets/}, %r{/support/}, %r{/(.+)_helper.}]
    coverage.ignore = [
      %r{/lib/ruby/gems/},
      %r{/vendor/assets/},
      %r{/support/},
      %r{/bin/},
      %r{/config/},
      %r{/coverage/},
      %r{/db/},
      %r{/lib/},
      %r{/log/},
      %r{/public/},
      %r{/spec/},
      %r{/tmp/},
      %r{/vendor/},
      %r{/app/controllers/},
      %r{/app/helpers/},
      %r{/app/mailers/},
      %r{/app/models/},
      %r{/app/views/},
      %r{/app/assets/images/},
      %r{/app/assets/stylesheets/},
      %r{/app/assets/javascripts/application.js},
      %r{/app/assets/javascripts/angular-app/directives/},
      %r{/app/assets/javascripts/angular-app/services/googleChartApiPromiseFactory.js.coffee},
      %r{/app/assets/javascripts/angular-app/ng-csv.js},
      %r{/app/assets/javascripts/gatag.js},
      %r{/app/assets/javascripts/lodash.js},
      %r{/(.+)_helper.},
      %r{/.gitignore},
      %r{/.rspec},
      %r{/.rubocop.yml},
      %r{/.rubocop_todo.yml},
      %r{/.ruby-gemset},
      %r{/.ruby-version},
      %r{/.travis.yml},
      %r{/config.ru},
      %r{/Gemfile},
      %r{/Gemfile.lock},
      %r{/Rakefile},
      %r{/README.md},
      %r{/.rvm/}
    ]

    # Various thresholds requirements can be defined, and those thresholds will be checked at the end of a run. If any
    # aren't met the run will fail with a message. Thresholds can be defined as a percentage (0-100), or nil.
    #coverage.statements = nil
    #coverage.functions = nil
    #coverage.branches = nil
    #coverage.lines = nil
  end
end
