module Watir
  class Capabilities
    attr_reader :browser_name, :driver, :http_client, :browser_version, :platform_name, :accept_insecure_certs,
                :page_load_strategy, :proxy, :set_window_rect, :timeouts, :unhandled_prompt_behavior, :capabilities,
                :listener

    SE_CLASSES = {chrome: 'Chrome',
                  firefox: 'Firefox',
                  ie: 'IE',
                  internet_explorer: 'IE',
                  edge: 'Edge',
                  safari: 'Safari'}

    W3C_OPTIONS = {browser_version: [String],
                   platform_name: [String],
                   accept_insecure_certs: [TrueClass, FalseClass],
                   page_load_strategy: [String],
                   set_window_rect: [TrueClass, FalseClass],
                   timeouts: [Hash],
                   unhandled_prompt_behavior: [String]}

    def initialize(browser_name, **watir_options)
      @browser_name = if browser_name.nil? || browser_name.is_a?(Hash)
                   raise unless watir_options.empty?

                   watir_options = browser_name.nil? ? {} : browser_name
                   :chrome
                 else
                   browser_name.downcase.to_sym
                 end

      @watir_options = watir_options || {}
      create_defaults

      Watir.logger.info "Creating Browser instance of #{@browser} with user provided options: " \
"#{watir_options.inspect}"

      #convert_browser(browser)
      #selenium_browser
      #create_options
      #@selenium_opts = {}
    end

    def create_defaults
      desired_capabilities
      w3c_options
      create_proxy
      create_listener
      self.driver = @watir_options.delete(:driver) || {}
      self.options = @watir_options.delete(:options) || {}
      self.http_client = @watir_options.delete(:http_client) || {}
    end

    def desired_capabilities
      return unless @watir_options.key?(:desired_capabilities)

      capabilities = @watir_options.delete(:desired_capabilities)

      capabilities.send(:capabilities).each do |key, value|
        if key == :browser_name
          @browser_name = value.downcase.to_sym
        elsif self.respond_to?(key)
          instance_variable_set("@#{key}", value)
        end
      end
    end

    def w3c_options
      W3C_OPTIONS.each do |key, type|
        value = @watir_options.delete(key)
        type_check(key, type, value)
        instance_variable_set("@#{key}", value) unless value.nil?
      end
    end

    def create_proxy
      proxy = @watir_options.delete(:proxy)
      return if proxy.nil?

      @proxy = if proxy.is_a?(Selenium::WebDriver::Proxy)
                 proxy
               else
                 Selenium::WebDriver::Proxy.new(proxy)
               end
    end

    def create_listener
      @listener = @watir_options.delete(:listener)
    end


    def options_class
      options = @watir_options.delete('options')
      options
    end

    def type_check(key, types, value)
      return if value.nil? || types.include?(value.class)

      raise TypeError, "Incorrect Type for #{key}, expected one of #{types}, but received #{value.class}"
    end

    def driver=(driver = {})
      return if @watir_options.key?(:url)

      driver[:path] ||= Selenium::WebDriver.const_get(SE_CLASSES[@browser_name]).driver_path
      driver[:port] ||= Selenium::WebDriver.const_get(SE_CLASSES[@browser_name])::Service::DEFAULT_PORT
      driver[:opt] ||= {}
      @driver = driver
    end

    def options=(options = {})
      @options = Selenium::WebDriver.const_get(SE_CLASSES[@browser_name])::Options.new(options)
    end

    def http_client=(http_client = {})
      @http_client = if http_client.is_a?(Selenium::WebDriver::Remote::Http::Common)
                       http_client
                     else
                       client = Selenium::WebDriver::Remote::Http::Default.new
                       open = http_client[:open_timeout] || http_client[:timeout]
                       read = http_client[:read_timeout] || http_client[:timeout]

                       client.open_timeout = open if open
                       client.read_timeout = read if read
                       client
                     end
    end

    def capabilities
      caps = @watir_options[:capabilities]
    end


    # def proxy
    #   @proxy ||= @watir_options[:proxy]
    # end

    def url
      @url ||= @watir_options[:url]
    end





    def to_args
      [@selenium_browser, process_arguments]
    end

    private

    def create_options_old
      options = @options.delete(options)
      return

    end

    def convert_browser(browser)
      if browser == :remote && @options.key?(:browser)
        @options.delete(:browser)
      elsif browser == :remote && @options.key?(:desired_capabilities)
        @options[:desired_capabilities].browser_name.to_sym
      else
        browser.to_sym
      end
    end

    def selenium_browser
      @selenium_browser = @browser == :remote || @options[:url] ? :remote : @browser
    end

    def process_arguments
      url = @options.delete(:url)
      @selenium_opts[:url] = url if url

      create_http_client

      @selenium_opts[:port] = @options.delete(:port) if @options.key?(:port)
      @selenium_opts[:driver_opts] = @options.delete(:driver_opts) if @options.key?(:driver_opts)
      @selenium_opts[:listener] = @options.delete(:listener) if @options.key?(:listener)

      process_browser_options
      process_capabilities
      Watir.logger.info "Creating Browser instance with Watir processed options: #{@selenium_opts.inspect}"

      @selenium_opts
    end

    def create_http_client
      client_timeout = @options.delete(:client_timeout)
      open_timeout = @options.delete(:open_timeout)
      read_timeout = @options.delete(:read_timeout)

      http_client = @options.delete(:http_client)

      %i[open_timeout read_timeout client_timeout].each do |t|
        next if http_client.nil? || !respond_to?(t)

        msg = "You can pass #{t} value directly into Watir::Browser opt without needing to use :http_client"
        Watir.logger.warn msg, ids: %i[http_client use_capabilities]
      end

      http_client ||= Selenium::WebDriver::Remote::Http::Default.new

      http_client.timeout = client_timeout if client_timeout
      http_client.open_timeout = open_timeout if open_timeout
      http_client.read_timeout = read_timeout if read_timeout
      @selenium_opts[:http_client] = http_client
    end

    # TODO: - this will get addressed with Capabilities Update
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/PerceivedComplexity:
    # rubocop:disable Metrics/CyclomaticComplexity::
    def process_browser_options
      browser_options = @options.delete(:options) || {}

      case @selenium_browser
      when :chrome
        if @options.key?(:args) || @options.key?(:switches)
          browser_options ||= {}
          browser_options[:args] = (@options.delete(:args) || @options.delete(:switches)).dup
        end
        if @options.delete(:headless)
          browser_options ||= {}
          browser_options[:args] ||= []
          browser_options[:args] += ['--headless', '--disable-gpu']
        end
        @selenium_opts[:options] = browser_options if browser_options.is_a? Selenium::WebDriver::Chrome::Options
        @selenium_opts[:options] ||= Selenium::WebDriver::Chrome::Options.new(browser_options)
      when :firefox
        profile = @options.delete(:profile)
        if browser_options.is_a? Selenium::WebDriver::Firefox::Options
          @selenium_opts[:options] = browser_options
          if profile
            msg = 'Initializing Browser with both :profile and :option', ':profile as a key inside :option'
            Watir.logger.deprecate msg, ids: [:firefox_profile]
          end
        end
        if @options.delete(:headless)
          browser_options ||= {}
          browser_options[:args] ||= []
          browser_options[:args] += ['--headless']
        end
        @selenium_opts[:options] ||= Selenium::WebDriver::Firefox::Options.new(browser_options)
        @selenium_opts[:options].profile = profile if profile
      when :safari
        Selenium::WebDriver::Safari.technology_preview! if @options.delete(:technology_preview)
      when :remote
        if @browser == :chrome && @options.delete(:headless)
          args = @options.delete(:args) || @options.delete(:switches) || []
          @options['chromeOptions'] = {'args' => args + ['--headless', '--disable-gpu']}
        end
        if @browser == :firefox && @options.delete(:headless)
          args = @options.delete(:args) || @options.delete(:switches) || []
          @options[Selenium::WebDriver::Firefox::Options::KEY] = {'args' => args + ['--headless']}
        end
        if @browser == :safari && @options.delete(:technology_preview)
          @options['safari.options'] = {'technologyPreview' => true}
        end
      when :ie
        if @options.key?(:args)
          browser_options ||= {}
          browser_options[:args] = @options.delete(:args).dup
        end
        unless browser_options.is_a? Selenium::WebDriver::IE::Options
          ie_caps = browser_options.select { |k| Selenium::WebDriver::IE::Options::CAPABILITIES.include?(k) }
          browser_options = Selenium::WebDriver::IE::Options.new(browser_options)
          ie_caps.each { |k, v| browser_options.add_option(k, v) }
        end
        @selenium_opts[:options] = browser_options
      end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/PerceivedComplexity:
    # rubocop:enable Metrics/CyclomaticComplexity::

    def process_capabilities
      caps = @options.delete(:desired_capabilities)

      if caps
        msg = 'You can pass values directly into Watir::Browser opt without needing to use :desired_capabilities'
        Watir.logger.warn msg,
                          ids: [:use_capabilities]
        @selenium_opts.merge!(@options)
      else
        caps = Selenium::WebDriver::Remote::Capabilities.send @browser, @options
      end

      @selenium_opts[:desired_capabilities] = caps
    end
  end
end
