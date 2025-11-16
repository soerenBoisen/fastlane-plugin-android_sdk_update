source 'https://rubygems.org'

# HACK: Needed until fastlane grows proper Ruby 3.4 support
gem "abbrev"
gem "mutex_m"
gem "ostruct"
gem "bigdecimal"
gem "nkf"

gemspec

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
