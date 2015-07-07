RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

RSpec::Expectations.configuration.warn_about_potential_false_positives = false
