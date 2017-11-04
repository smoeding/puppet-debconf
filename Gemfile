source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :test do
  gem 'puppetlabs_spec_helper',     :require => false
  gem 'rspec-puppet',               :require => false
  gem 'rspec-puppet-facts',         :require => false
  gem 'semantic_puppet',            :require => false
  gem 'rubocop', '~> 0.49.1',       :require => false if RUBY_VERSION >= '2.3.0'
  gem 'rubocop-rspec', '~> 1.15.0', :require => false if RUBY_VERSION >= '2.3.0'
  gem 'json', '< 2.0.0',            :require => false if RUBY_VERSION < '2.0.0'
  gem 'json_pure', '< 2.0.0',       :require => false if RUBY_VERSION < '2.0.0'
end

if RUBY_VERSION < '2.0.0'
  gem 'metadata-json-lint', '< 1.2.0', :require => false, :groups => [:test]
else
  gem 'metadata-json-lint', :require => false, :groups => [:test]
end

ENV['PUPPET_GEM_VERSION'].nil? ? puppetversion = '~> 4.0' : puppetversion = ENV['PUPPET_GEM_VERSION'].to_s
gem 'puppet', puppetversion, :require => false, :groups => [:test]
