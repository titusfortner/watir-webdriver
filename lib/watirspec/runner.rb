module WatirSpec
  module Runner

    module BrowserHelper
      def browser
        $browser
      end
    end

    module MessagesHelper
      def messages
        browser.div(id: 'messages').divs.map(&:text)
      end
    end

    module_function

    @execute = true

    def execute=(bool)
      @execute = bool
    end

    def execute
      start_server
      configure
      add_guard_hook

      @executed = true
    end

    def execute_if_necessary
      execute if !@executed && @execute
    end

    def configure
      Thread.abort_on_exception = true
      return unless defined?(RSpec)

      RSpec.configure do |config|
        config.include(BrowserHelper)
        config.include(MessagesHelper)

        if WatirSpec.implementation.name == :sauce
          config.before(:each) do |example|
            capabilities = {name: example.full_description,
                            build: ENV['BUILD_TAG'] ||= "Unknown Build - #{Time.now.to_i}"}
            platforms = YAML.load_file("lib/watirspec/config/platforms.yml")
            platform = platforms[ENV['PLATFORM'] || 'mac_high_sierra_chrome']

            platform.each { |k, v| capabilities[k] = v }

            WatirSpec.implementation.browser_args.last.merge!(desired_capabilities: capabilities)

            $browser = WatirSpec.new_browser
          end

          config.after(:each) do |example|
            $browser.execute_script("sauce:job-result=#{!example.exception}")
            $browser.close
          end
        else
          config.before(:suite) { $browser = WatirSpec.new_browser }
          config.after(:suite) { $browser.close }
        end
      end
    end

    def start_server
      WatirSpec::Server.run!
    end

    def add_guard_hook
      return if WatirSpec.unguarded?
      at_exit { WatirSpec::Guards.report } unless WatirSpec.implementation.name == :sauce
    end

  end # Runner
end # WatirSpec
