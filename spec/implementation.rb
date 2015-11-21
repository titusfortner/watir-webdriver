require 'spec_helper'

class ImplementationConfig
  def initialize(imp)
    @imp = imp
  end

  def configure
    @imp.browser_class = Watir::Browser
    start_remote_server if browser == :remote
    set_browser_args
    set_guard_proc
    add_html_routes

    WatirSpec.always_use_server = safari? || remote?
  end

  private

  def start_remote_server
    require 'selenium/server'

    @server ||= Selenium::Server.new(remote_server_jar,
                                     :port       => Selenium::WebDriver::PortProber.above(4444),
                                     :log        => !!$DEBUG,
                                     :background => true,
                                     :timeout    => 60)


    if remote_browser == :marionette
      @server << "-Dwebdriver.firefox.bin=#{ENV['MARIONETTE_PATH']}"
    end
    @server.start
  end

  def remote_server_jar
    require 'open-uri'
    file_name = "selenium-server-standalone.jar"
    return file_name if File.exist? file_name

    open(file_name, 'wb') do |file|
      file << open('http://goo.gl/PJUZfa').read
    end
    file_name
  rescue SocketError
    raise Watir::Error, "unable to find or download selenium-server-standalone.jar in #{Dir.pwd}"
  end


  def set_browser_args
    args = case browser
             when :firefox
               firefox_args
             when :marionette
               marionette_args
             when :chrome
               chrome_args
             when :remote
               remote_args
             else
               [browser, {}]
           end

    if ENV['SELECTOR_STATS']
      listener = SelectorListener.new
      args.last.merge!(listener: listener)
      at_exit { listener.report }
    end

    @imp.browser_args = args
  end

  def ie?
    browser == :internet_explorer
  end

  def safari?
    browser == :safari
  end

  def phantomjs?
    browser == :phantomjs
  end

  def remote?
    browser == :remote
  end

  def set_guard_proc
    matching_browser = remote? ? remote_browser : browser
    browser_instance = WatirSpec.new_browser
    browser_version = browser_instance.driver.capabilities.version
    matching_browser_with_version = "#{matching_browser}#{browser_version}".to_sym
    matching_guards = [
      matching_browser,               # guard only applies to this browser
      matching_browser_with_version,  # guard only applies to this browser with specific version
      [matching_browser, Selenium::WebDriver::Platform.os] # guard only applies to this browser with this OS
    ]

    if !Selenium::WebDriver::Platform.linux? || ENV['DESKTOP_SESSION']
      matching_guards << [:window_manager]
    end

    @imp.guard_proc = lambda { |args|
      args.any? { |arg| matching_guards.include?(arg) }
    }
  ensure
    browser_instance.close if browser_instance
  end

  def firefox_args
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.native_events = native_events?

    [:firefox, {profile: profile}]
  end

  def marionette_args
    caps = Selenium::WebDriver::Remote::W3CCapabilities.firefox
    [:firefox, {desired_capabilities: caps}]
  end

  def chrome_args
    opts = {
      args: ["--disable-translate"]
    }

    if url = ENV['WATIR_WEBDRIVER_CHROME_SERVER']
      opts[:url] = url
    end

    if driver = ENV['WATIR_WEBDRIVER_CHROME_DRIVER']
      Selenium::WebDriver::Chrome.driver_path = driver
    end

    if path = ENV['WATIR_WEBDRIVER_CHROME_BINARY']
      Selenium::WebDriver::Chrome.path = path
    end

    if ENV['TRAVIS']
      opts[:args] << "--no-sandbox" # https://github.com/travis-ci/travis-ci/issues/938
    end

    [:chrome, opts]
  end

  def remote_args
    url = ENV["WATIR_WEBDRIVER_REMOTE_URL"] || "http://127.0.0.1:#{@server.port}/wd/hub"
    if remote_browser == :marionette
      caps = Selenium::WebDriver::Remote::W3CCapabilities.firefox
    else
      caps = Selenium::WebDriver::Remote::Capabilities.send(remote_browser)
    end
    [:remote, { url: url,
                desired_capabilities: caps}]
  end

  def add_html_routes
    glob = File.expand_path("../html/*.html", __FILE__)
    Dir[glob].each do |path|
      WatirSpec::Server.get("/#{File.basename path}") { File.read(path) }
    end
  end

  def browser
    @browser ||= (ENV['WATIR_WEBDRIVER_BROWSER'] || :firefox).to_sym
  end

  def remote_browser
    @remote_browser ||= (ENV['REMOTE_BROWSER'] || :firefox).to_sym
  end

  def native_events?
    ENV['NATIVE_EVENTS'] == "true" || browser == :internet_explorer
  end

  class SelectorListener < Selenium::WebDriver::Support::AbstractEventListener
    def initialize
      @counts = Hash.new(0)
    end

    def before_find(how, what, driver)
      @counts[how] += 1
    end

    def report
      total = @counts.values.inject(0) { |mem, var| mem + var }
      puts "\nWebDriver selector stats: "
      @counts.each do |how, count|
        puts "\t#{how.to_s.ljust(20)}: #{count * 100 / total} (#{count})"
      end
    end

  end
end

ImplementationConfig.new(WatirSpec.implementation).configure
