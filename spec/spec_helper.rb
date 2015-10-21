# encoding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'coveralls'
Coveralls.wear!

require 'watir-webdriver'
require 'locator_spec_helper'
require 'rubygems'
require 'rspec'
require "tmpdir"
require "sinatra/base"
require "#{File.dirname(__FILE__)}/lib/watirspec"
require "#{File.dirname(__FILE__)}/lib/implementation"
require "#{File.dirname(__FILE__)}/lib/server"
require "#{File.dirname(__FILE__)}/lib/runner"
require "#{File.dirname(__FILE__)}/lib/guards"
require "#{File.dirname(__FILE__)}/lib/silent_logger"

include Watir

if ENV['ALWAYS_LOCATE'] == "false"
  Watir.always_locate = false
end

if ENV['PREFER_CSS']
  Watir.prefer_css = true
end

WEBDRIVER_SELECTORS = %i(class class_name css id tag_name xpath)

if ENV['TRAVIS']
  ENV['DISPLAY'] = ":99.0"

  if ENV['WATIR_WEBDRIVER_BROWSER'] == "chrome"
    ENV['WATIR_WEBDRIVER_CHROME_BINARY'] = File.expand_path "chrome-linux/chrome"
    ENV['WATIR_WEBDRIVER_CHROME_DRIVER'] = File.expand_path "chrome-linux/chromedriver"
  end
end

if Selenium::WebDriver::Platform.linux? && ENV['DISPLAY'].nil?
  raise "DISPLAY not set"
end

begin
  require "rubygems"
rescue LoadError
end


if __FILE__ == $0
  # this is needed in order to have a stable Server on Windows + MRI
  WatirSpec::Server.run!
else
  WatirSpec::Runner.execute_if_necessary
end

