require_relative 'unit_helper'

# Optional:
# :listener
# :http_client
# :proxy
#
# Optional Local
# :service
# :options
#
# Required Remote
# :options or :capabilities
# :url
#

# Capabilities accessors:
# browser
# service
# url ?
# http_client
# proxy
# options
# capabilities ?
# listener

module Watir
  describe Capabilities do
    describe '#new' do
      let(:capabilities) { described_class.new(@options || {}) }

      context 'with defaults' do
        it 'browser to Chrome' do
          expect(capabilities.browser).to eq :chrome
        end

        it 'allows additional options without specifying a browser' do
          @options = {foo: 'bar'}
          expect(capabilities.browser).to eq :chrome
        end

        it 'chrome options' do
          default_options = Selenium::WebDriver::Chrome::Options.new

          expect(capabilities.options.as_json).to eq default_options.as_json
        end

        it 'chromedriver service' do
          default_service = Selenium::WebDriver::Chrome::Service.new(nil, 9515, {})

          %i[executable_path port args].all? do |instance|
            default_value = default_service.instance_variable_get("@#{instance}")
            expect(capabilities.service.instance_variable_get("@#{instance}")).to eq default_value
          end
        end

        it 'http client' do
          default_http_client = Selenium::WebDriver::Remote::Http::Default.new

          %i[open_timeout read_timeout proxy].all? do |instance|
            default_value = default_http_client.instance_variable_get("@#{instance}")
            expect(capabilities.http_client.instance_variable_get("@#{instance}")).to eq default_value
          end
        end

        it 'does not create default listener' do
          expect(capabilities.listener).to be_nil
        end

        it 'does not create default proxy' do
          expect(capabilities.proxy).to be_nil
        end

        # TODO: Does url need to be its own method?
        it 'does not create default url' do
          expect(capabilities.url).to be_nil
        end
      end

      context 'with specific browser options' do
        it 'specifies browser' do
          @options = :firefox
          expect(capabilities.browser).to eq :firefox
        end

        it 'uses remote if url is specified' do
          url = 'http://localhost:4444/wd/hub'
          @options = {url: url}
          expect(capabilities.url).to eq url
        end



        it 'does not allow args to be passed in directly' do
          @options = {args: %w[--foo]}

          msg = 'Do not pass :args values directly, put inside options Hash: {options: {args: %w[--foo]}}'
          expect { capabilities.args }.to raise_exception CapabilitiesException, msg
        end
        it 'does not allow binary to be passed in directly'
        it 'does not allow prefs to be passed in directly'
      end


      context 'with Selenium Classes alone' do
        it 'Capabilities class pre-defined' do
          # throw deprecation warning
          se_caps = Selenium::WebDriver::Remote::Capabilities.chrome

          caps = described_class.new(capabilities: se_caps)

          expect(caps.capabilities).to eq se_caps
        end

        it 'accepts alternate browser with symbol'
        it 'accepts alternate browser with capitalized string'

        it 'Capabilities class with raw Hash' do
          # this is the catch-all workaround for any crazy stuff that Watir/Selenium aren't supporting directly for some reason
          se_caps = {browser_name: 'chrome', browser_version: '68', platform_name: 'Windows'}
          expected_capabilities = Selenium::WebDriver::Remote::Capabilities.new(se_caps)

          caps = described_class.new(desired_capabilities: se_caps)

          expect(caps.capabilities).to eq expected_capabilities
        end

        it 'Service class' do
          # TODO: update Selenium to have defaults for service object
          service = Selenium::WebDriver::Chrome::Service.new(nil, 9515, {})

          caps = described_class.new(service: service)

          expect(caps.service).to eql service
        end

        it 'Options class' do
          options = Selenium::WebDriver::Chrome::Options.new(args: %w[--foo])

          caps = described_class.new(options: options)

          expect(caps.options).to eql options
        end

        it 'HTTP client' do
          http_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 42)

          caps = described_class.new(http_client: http_client)

          expect(caps.http_client).to eql http_client
        end

        it 'Proxy' do
          proxy = Selenium::WebDriver::Proxy.new(type: 'MANUAL')

          caps = described_class.new(proxy: proxy)

          expect(caps.proxy).to eql proxy
        end

        it 'Profile' do
          profile = Selenium::WebDriver::Chrome::Profile.new(profile_directory)
          profile.add_extension(extension_path)

          caps = described_class.new(profile: profile)

          expect(caps.profile).to eql profile
        end
      end

      context 'with Selenium Classes and parameters' do
        it 'timeouts override HTTP Client class parameters' do
          default_http_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 24)
          opts = {http_client: default_http_client, open_timeout: 42}
          expected_http_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 42)

          expect(described_class.new(opts)).to eq expected_http_client
        end

        it 'adds headless to Options class' do
          options = Selenium::WebDriver::Chrome::Options.new
          expected_options = Selenium::WebDriver::Chrome::Options.new.headless!
          capabilities = described_class.new(headless: true, options: options)

          expect(capabilities.options).to eql(expected_options)
        end

        it 'mobile values override Options class' do
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_emulation(device_name: 'iPhone 6')

          capabilities = described_class.new(mobile: 'iPhone X', options: options)

          expect(capabilities.options.emulation[:deviceName]).to eq('iPhone X')
        end

        it 'profile value overrides Options Class' do
          path1 = '/path/to/profile1'
          path2 = '/path/to/profile2'

          options = Selenium::WebDriver::Chrome::Options.new(args: ["user-data-dir=#{path1}"])

          capabilities = described_class.new(profile: path2, options: options)

          expect(capabilities.profile.instance_variable_get('@model')).to eq(path2)
        end

        it 'adds extensions to provided Profile Class' do
          profile_path = '/path/to/profile'
          extension_path = '/path/to/extension'

          selenium_profile = Selenium::WebDriver::Chrome::Profile.new(profile_path)
          expected_profile = Selenium::WebDriver::Chrome::Profile.new(profile_path)
          expected_profile.add_extension(extension_path)

          capabilities = described_class.new(extensions: [extension_path], profile: selenium_profile)

          expect(capabilities.profile.instance_variable_get('@model')).to eq(profile_path)
          expect(capabilities.profile.instance_variable_get('@extensions')).to eq(extension_path)
        end

        it 'driver values override Service Class' do
          path1 = '/path/to/driver1'
          path2 = '/path/to/driver2'

          service = Selenium::WebDriver::Chrome::Service.new(path1, 1234, {verbose: true, log_path: log_path})
          expected_service = Selenium::WebDriver::Chrome::Service.new(path2, 5678, {verbose: false, log_path: log_path})

          capabilities = described_class.new(service: service, driver: {path: path2, port: 5678, verbose: false})
          expect(capabilities.service).to eq(expected_service)
        end

        it 'driver path override Service Class' do
          path1 = '/path/to/driver1'
          path2 = '/path/to/driver2'

          service = Selenium::WebDriver::Chrome::Service.new(path1, 1234, {})
          expected_service = Selenium::WebDriver::Chrome::Service.new(path2, 1234, {})

          capabilities = described_class.new(driver_path: path2, service: service)
          expect(capabilities.service).to eq(expected_service)
        end
      end


      context 'Builds Selenium Objects' do
        it 'Builds HTTP class' do
          expected_http_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 42)

          capabilities = described_class.new(open_timeout: 42)

          expect(capabilities.http_client).to eq expected_http_client
        end

        it 'builds Options class' do
          opts = {args: args, binary: binary, prefs: prefs, extensions: extensions, options: options, emulation: emulation}
          capabilities = described_class.new(options: opts)
          expect(capabilities.options.args).to eq(args)
          expect(capabilities.options.binary).to eq(binary)
          expect(capabilities.options.prefs).to eq(prefs)
          expect(capabilities.options.extensions).to eq(extensions)
          expect(capabilities.options.options).to eq(options)
          expect(capabilities.options.emulation).to eq(emulation)
        end

        it 'builds Service Class' do
          expected_service = Selenium::WebDriver::Chrome::Service.new('/path/to/driver', 5678, {verbose: true})

          capabilities = described_class.new(driver: {path: '/path/to/driver', port: 5678, verbose: true})
          expect(capabilities.service).to eq(expected_service)
        end

        it 'builds Profile Class' do
          profile_path = '/path/to/profile'
          extension_path = '/path/to/extension'

          expected_profile = Selenium::WebDriver::Chrome::Profile.new(profile_path)
          expected_profile.add_extension(extension_path)

          capabilities = described_class.new(profile: profile_path, extensions: [extension_path])

          expect(capabilities.profile).to eq(expected_profile)
        end

        it 'builds Proxy Class' do
          proxy = Selenium::WebDriver::Proxy.new(type: 'MANUAL')

          caps = described_class.new(proxy: {type: 'MANUAL'})

          expect(caps.proxy).to eql proxy
        end
      end

      context 'with specific vendor options' do
        it 'works with Sauce!' do
          sauce_options = {browser_name: 'Chrome', platform_name: 'Windows 10', sauce_username: ENV['SAUCE_USERNANE'],
                           sauce_access_key: ENV['SAUCE_ACCESS_KEY']}
          capabilities = described_class.new(sauce: sauce_options)

          expected_capabilities = '????'

          expect(capabilities.sauce).to eq(expected_capabilities)
        end
      end
    end

    describe '#to_args' do
      it 'does the right thing' do
        capabilities = instance_double described_class
        allow(capabilities).to receive(:capabilities).and_return(Selenium::WebDriver::Remote::Capabilities.chrome)
        # a buncha more allows here
        expect(capabilities.to_args).to eq(desired_capabilities: capabilities)
      end
    end

    describe '#ie' do
      it 'processes options' do
        options = {browser_attach_timeout: 1, full_page_screenshot: true}
        caps = described_class.new(:ie, options: options)
        opts = caps.to_args.last[:options]
        expect(opts.browser_attach_timeout).to eq 1
        expect(opts.full_page_screenshot).to be true
      end

      it 'processes args' do
        caps = described_class.new(:ie, args: %w[foo bar])
        opts = caps.to_args.last[:options]
        expect(opts.args).to eq Set.new(%w[foo bar])
      end

      it 'processes options class' do
        options = Selenium::WebDriver::IE::Options.new(browser_attach_timeout: 1, full_page_screenshot: true)
        caps = described_class.new(:ie, options: options)
        opts = caps.to_args.last[:options]
        expect(opts.browser_attach_timeout).to eq 1
        expect(opts.full_page_screenshot).to be true
      end
    end
  end
end