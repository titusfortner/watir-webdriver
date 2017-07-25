require 'nokogiri'

module WatirSpec
  class RemoteServer
    attr_reader :server

    def start(port = 4444)
      require 'selenium/server'

      @server ||= Selenium::Server.new(jar,
                                       port: Selenium::WebDriver::PortProber.above(port),
                                       log: !!$DEBUG,
                                       background: true,
                                       timeout: 60)

      @server.start

      puts @server.webdriver_url
      puts Nokogiri::XML.parse(OpenURI.open_uri(@server.webdriver_url)).text
      at_exit { @server.stop }
    end

    private

    def jar
      warn "locating JAR"
      if ENV['LOCAL_SELENIUM']
        local = File.expand_path('../selenium/buck-out/gen/java/server/src/org/openqa/grid/selenium/selenium.jar')
      end

      if File.exist?(ENV['REMOTE_SERVER_BINARY'] || '')
        warn "found it specified at #{ENV['REMOTE_SERVER_BINARY']}"
        ENV['REMOTE_SERVER_BINARY']
      elsif ENV['LOCAL_SELENIUM'] && File.exists?(local)
        warn "found it local at #{ENV['LOCAL_SELENIUM']}"
        local
      elsif !Dir.glob('*selenium*.jar').empty?
        warn "found it local already}"
        Dir.glob('*selenium*.jar').first
      else
        warn "downloading it to #{Dir.pwd}"
        Selenium::Server.download :latest
      end
    rescue SocketError
      # not connected to internet
      raise Watir::Exception::Error, "unable to find or download selenium-server-standalone jar"
    end
  end
end