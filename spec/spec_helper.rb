# encoding: utf-8
# encoding: utf-8
begin
  require "rubygems"
rescue LoadError
end

require "tmpdir"
require "sinatra/base"
require "rspec"
require "fileutils"

require_relative 'lib/watirspec'
require_relative 'lib/guards'
require_relative 'lib/implementation'
require_relative 'lib/runner'
require_relative 'lib/server'
require_relative 'lib/silent_logger'


require 'coveralls'
Coveralls.wear!

require 'watir'
require 'rubygems'
require "tmpdir"
require "sinatra/base"
require 'locator_spec_helper'


if ENV['ALWAYS_LOCATE'] == "false"
  Watir.always_locate = false
end

if ENV['PREFER_CSS']
  Watir.prefer_css = true
end

SELENIUM_SELECTORS = %i(class class_name css id tag_name xpath)

if ENV['TRAVIS']
  ENV['DISPLAY'] = ":99.0"

  if ENV['WATIR_BROWSER'] == "chrome"
    ENV['WATIR_CHROME_BINARY'] = File.expand_path "chrome-linux/chrome"
    ENV['WATIR_CHROME_DRIVER'] = File.expand_path "chrome-linux/chromedriver"
  end
end

if Selenium::WebDriver::Platform.linux? && ENV['DISPLAY'].nil?
  raise "DISPLAY not set"
end


require_relative "lib/implementation_config"

begin
  require "ruby-debug"
  Debugger.start
  Debugger.settings[:autoeval] = true
  Debugger.settings[:autolist] = 1
rescue LoadError
end


if __FILE__ == $0
  # this is needed in order to have a stable Server on Windows + MRI
  WatirSpec::Server.run!
else
  WatirSpec::Runner.execute_if_necessary
end
