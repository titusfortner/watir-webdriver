module Watir
  class Capabilities
    attr_reader :browser_name, :driver, :http_client, :browser_version, :platform_name, :accept_insecure_certs,
                :page_load_strategy, :proxy, :set_window_rect, :timeouts, :unhandled_prompt_behavior, :capabilities,
                :listener, :browser_options, :url

    SE_CLASSES = {chrome: 'Chrome',
                  firefox: 'Firefox',
                  ie: 'IE',
                  internet_explorer: 'IE',
                  edge: 'Edge',
                  safari: 'Safari'}.freeze

    W3C_OPTIONS = {browser_version: [String],
                   platform_name: [String],
                   accept_insecure_certs: [TrueClass, FalseClass],
                   page_load_strategy: [String],
                   set_window_rect: [TrueClass, FalseClass],
                   timeouts: [Hash],
                   unhandled_prompt_behavior: [String]}.freeze

    def initialize(browser_name, **watir_options)
      disambiguate_options(browser_name, **watir_options)

      Watir.logger.info "Creating Browser instance of #{@browser} with user provided options: " \
"#{watir_options.inspect}"

      @extra_options = {}

      # If these are Selenium classes, we do not want to convert them
      # There are no alternative overrides, so no reason to store as Hashes
      @proxy = @watir_options.delete(:proxy)
      @http_client = @watir_options.delete(:http_client)
      @listener = @watir_options.delete(:listener)

      @url = @watir_options.delete(:url)

      # This has no equivalent Selenium class at this point
      @driver = @watir_options.delete(:driver) || {} unless @url

      parse_desired_capabilities
      parse_w3c_options
      parse_browser_options
      validate_remaining
    end

    def to_selenium
      [@selenium_browser, process_arguments]
    end

    private

    def disambiguate_options(browser_name, **watir_options)
      @browser_name = if browser_name.is_a?(Hash)
                        parse_browser_name(browser_name)
                      elsif browser_name.nil?
                        parse_browser_name(watir_options)
                      else
                        @watir_options = watir_options
                        browser_name.downcase.to_sym
                      end
    end

    # Go through the different ways a browser might be set in options
    def parse_browser_name(options)
      @watir_options = options

      browser_name = (@watir_options.keys & SE_CLASSES.keys).first
      browser_string = @watir_options[:browser_options]&.class&.to_s&.split('::')
      browser_name ||= SE_CLASSES.key(browser_string[2]) unless browser_string.nil?
      browser_name ||= @watir_options[:desired_capabilities]&.browser_name
      browser_name || :chrome
    end

    # TODO: Should we deprecate this for Selenium 4?
    # TODO: Should we deprecate allowing extra options for Selenium 4?
    def parse_desired_capabilities
      capabilities = @watir_options.delete :desired_capabilities
      return if capabilities.nil?

      capabilities.send(:capabilities).each do |key, value|
        if respond_to?(key) && key != :browser_name
          instance_variable_set("@#{key}", value)
        else
          @extra_options[key] = value
        end
      end
    end

    def parse_w3c_options
      W3C_OPTIONS.each do |key, type|
        value = @watir_options.delete(key)
        type_check(key, type, value)
        instance_variable_set("@#{key}", value) unless value.nil?
      end
    end

    def parse_browser_options
      browser_options = @watir_options.delete(:browser_options)
      general_options = if browser_options.nil?
                          {}
                        elsif !browser_options.is_a?(Hash)
                          convert_se_options(browser_options)
                        else
                          browser_options
                        end
      browser_options = @watir_options.delete(@browser_name)
      specific_options = if browser_options.nil?
                           {}
                         elsif !browser_options.is_a?(Hash)
                           convert_se_options(browser_options)
                         else
                           browser_options
                         end
      @browser_options = general_options.merge(specific_options)
    end

    def convert_se_options(options)
      options.instance_variables.each_with_object({}) do |method, hash|
        value = options.instance_variable_get(method)
        value = value.to_a if value.is_a?(Set)
        hash[method.to_s.tr('@', '').to_sym] = value
      end
    end

    def type_check(key, types, value)
      return if value.nil? || types.include?(value.class)

      raise TypeError, "Incorrect Type for #{key}, expected one of #{types}, but received #{value.class}"
    end

    def validate_remaining
      return if @watir_options.empty?

      msg = "#{@watir_options.keys} is not allowed as a direct argument, see allowed values: " \
'http://watir.com/guides/capabilities'
      raise ArgumentError, msg
    end

    # def create_options_old
    #   options = @options.delete(options)
    #   return
    #
    # end
    #
    # def convert_browser(browser)
    #   if browser == :remote && @options.key?(:browser)
    #     @options.delete(:browser)
    #   elsif browser == :remote && @options.key?(:desired_capabilities)
    #     @options[:desired_capabilities].browser_name.to_sym
    #   else
    #     browser.to_sym
    #   end
    # end
    #
    # def selenium_browser
    #   @selenium_browser = @browser == :remote || @options[:url] ? :remote : @browser
    # end
    #
    # def process_arguments
    #   url = @options.delete(:url)
    #   @selenium_opts[:url] = url if url
    #
    #   create_http_client
    #
    #   @selenium_opts[:port] = @options.delete(:port) if @options.key?(:port)
    #   @selenium_opts[:driver_opts] = @options.delete(:driver_opts) if @options.key?(:driver_opts)
    #   @selenium_opts[:listener] = @options.delete(:listener) if @options.key?(:listener)
    #
    #   process_browser_options
    #   process_capabilities
    #   Watir.logger.info "Creating Browser instance with Watir processed options: #{@selenium_opts.inspect}"
    #
    #   @selenium_opts
    # end
    #
    # def create_http_client_old
    #   client_timeout = @options.delete(:client_timeout)
    #   open_timeout = @options.delete(:open_timeout)
    #   read_timeout = @options.delete(:read_timeout)
    #
    #   http_client = @options.delete(:http_client)
    #
    #   %i[open_timeout read_timeout client_timeout].each do |t|
    #     next if http_client.nil? || !respond_to?(t)
    #
    #     msg = "You can pass #{t} value directly into Watir::Browser opt without needing to use :http_client"
    #     Watir.logger.warn msg, ids: %i[http_client use_capabilities]
    #   end
    #
    #   http_client ||= Selenium::WebDriver::Remote::Http::Default.new
    #
    #   http_client.timeout = client_timeout if client_timeout
    #   http_client.open_timeout = open_timeout if open_timeout
    #   http_client.read_timeout = read_timeout if read_timeout
    #   @selenium_opts[:http_client] = http_client
    # end
    #
    # # TODO: - this will get addressed with Capabilities Update
    # def process_browser_options
    #   browser_options = @options.delete(:options) || {}
    #
    #   case @selenium_browser
    #   when :chrome
    #     if @options.key?(:args) || @options.key?(:switches)
    #       browser_options ||= {}
    #       browser_options[:args] = (@options.delete(:args) || @options.delete(:switches)).dup
    #     end
    #     if @options.delete(:headless)
    #       browser_options ||= {}
    #       browser_options[:args] ||= []
    #       browser_options[:args] += ['--headless', '--disable-gpu']
    #     end
    #     @selenium_opts[:options] = browser_options if browser_options.is_a? Selenium::WebDriver::Chrome::Options
    #     @selenium_opts[:options] ||= Selenium::WebDriver::Chrome::Options.new(browser_options)
    #   when :firefox
    #     profile = @options.delete(:profile)
    #     if browser_options.is_a? Selenium::WebDriver::Firefox::Options
    #       @selenium_opts[:options] = browser_options
    #       if profile
    #         msg = 'Initializing Browser with both :profile and :option', ':profile as a key inside :option'
    #         Watir.logger.deprecate msg, ids: [:firefox_profile]
    #       end
    #     end
    #     if @options.delete(:headless)
    #       browser_options ||= {}
    #       browser_options[:args] ||= []
    #       browser_options[:args] += ['--headless']
    #     end
    #     @selenium_opts[:options] ||= Selenium::WebDriver::Firefox::Options.new(browser_options)
    #     @selenium_opts[:options].profile = profile if profile
    #   when :safari
    #     Selenium::WebDriver::Safari.technology_preview! if @options.delete(:technology_preview)
    #   when :remote
    #     if @browser == :chrome && @options.delete(:headless)
    #       args = @options.delete(:args) || @options.delete(:switches) || []
    #       @options['chromeOptions'] = {'args' => args + ['--headless', '--disable-gpu']}
    #     end
    #     if @browser == :firefox && @options.delete(:headless)
    #       args = @options.delete(:args) || @options.delete(:switches) || []
    #       @options[Selenium::WebDriver::Firefox::Options::KEY] = {'args' => args + ['--headless']}
    #     end
    #     if @browser == :safari && @options.delete(:technology_preview)
    #       @options['safari.options'] = {'technologyPreview' => true}
    #     end
    #   when :ie
    #     if @options.key?(:args)
    #       browser_options ||= {}
    #       browser_options[:args] = @options.delete(:args).dup
    #     end
    #     unless browser_options.is_a? Selenium::WebDriver::IE::Options
    #       ie_caps = browser_options.select { |k| Selenium::WebDriver::IE::Options::CAPABILITIES.include?(k) }
    #       browser_options = Selenium::WebDriver::IE::Options.new(browser_options)
    #       ie_caps.each { |k, v| browser_options.add_option(k, v) }
    #     end
    #     @selenium_opts[:options] = browser_options
    #   end
    # end
    #

    #
    # def process_capabilities
    #   caps = @options.delete(:desired_capabilities)
    #
    #   if caps
    #     msg = 'You can pass values directly into Watir::Browser opt without needing to use :desired_capabilities'
    #     Watir.logger.warn msg,
    #                       ids: [:use_capabilities]
    #     @selenium_opts.merge!(@options)
    #   else
    #     caps = Selenium::WebDriver::Remote::Capabilities.send @browser, @options
    #   end
    #
    #   @selenium_opts[:desired_capabilities] = caps
    # end
  end
end
