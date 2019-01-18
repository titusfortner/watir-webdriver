require_relative 'unit_helper'

# Optional:
# :listener
# :http_client
# :proxy
#
# Optional Local
# :service or :driver ?
# :options
#
# Required Remote
# :options or :capabilities
# :url
#
# W3C:
# browser_name, browser_version, platform_name, accept_insecure_certs, page_load_strategy, proxy
# set_window_rect, timeouts, strict_file_interactibility, unhandled_prompt_behavior
#
#

describe 'placeholder'

# Chrome:
# :args, :prefs, :options, :emulation, :extensions, :encoded_extensions
#
# Chromedriver options:
# args, binary, extensions, localState, prefs, detach, debuggerAddress, excludeSwitches, minidumpPath,
# mobileEmulation, perfLoggingPrefs, windowTypes
#
# Chromedriver --help
#
# port, adb-port, log-path, log-level, verbose (log-level=ALL), silent (log-level=OFF), append-log, replayable,
# version, url-base, whitelisted-ips
#
# Firefox:
# :args, :prefs, :options, :profile
#
# Geckodriver:
# :binary, :args, :profile, :log, :prefs
#
#                 browser_options: {accessibilityChecks: false,
#                                   geckodriverVersion: "0.23.0",
#                                   headless: false,
#                                   processID: 35752,
#                                   profile: "/var/folders/px/f7vkwk593ks8tv32dzzzk1lh0000gn/T/rust_mozprofile.bQhtJvoIqMzj",
#                                   shutdownTimeout: 60000,
#                                   useNonSpecCompliantPointerOrigin: false,
#                                   webdriverClick: true},
#
# Edge:
# in_private, :start_page extension_paths
#
# IE
#           browser_attach_timeout: 'browserAttachTimeout',
#           element_scroll_behavior: 'elementScrollBehavior',
#           full_page_screenshot: 'ie.enableFullPageScreenshot',
#           ensure_clean_session: 'ie.ensureCleanSession',
#           file_upload_dialog_timeout: 'ie.fileUploadDialogTimeout',
#           force_create_process_api: 'ie.forceCreateProcessApi',
#           force_shell_windows_api: 'ie.forceShellWindowsApi',
#           ignore_protected_mode_settings: 'ignoreProtectedModeSettings',
#           ignore_zoom_level: 'ignoreZoomSetting',
#           initial_browser_url: 'initialBrowserUrl',
#           native_events: 'nativeEvents',
#           persistent_hover: 'enablePersistentHover',
#           require_window_focus: 'requireWindowFocus',
#           use_per_process_proxy: 'ie.usePerProcessProxy',
#           validate_cookie_document_type: 'ie.validateCookieDocumentType'
#
# Safari:
# automatic_inspection, :automatic_profiling
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

      describe 'browser name' do
        it 'defaults to Chrome' do
          expect(capabilities.browser_name).to eq :chrome
        end

        it 'specifies browser with Symbol' do
          %i[firefox ie chrome edge safari].each do |browser|
            capabilities = described_class.new(browser)
            expect(capabilities.browser_name).to eq browser
          end
        end

        it 'specifies browser with String regardless of capitalization' do
          %w[Firefox iE chRome EDGE safarI].each do |browser|
            capabilities = described_class.new(browser)
            expect(capabilities.browser_name).to eq browser.downcase.to_sym
          end
        end
      end

      describe 'driver arguments' do
        it 'defaults to chromedriver service and only creates path and port' do
          path = '/driver/path'
          port = Selenium::WebDriver::Chrome::Service::DEFAULT_PORT
          driver_opts = {path: path, port: port}

          expect(Selenium::WebDriver::Chrome).to receive(:driver_path).and_return(path)
          expect(capabilities.driver).to eq(driver_opts)
        end

        it 'uses the service based on browser provided' do
          path = '/driver/path'
          port = Selenium::WebDriver::Firefox::Service::DEFAULT_PORT
          driver_opts = {path: path, port: port}

          expect(Selenium::WebDriver::Firefox).to receive(:driver_path).and_return(path)
          expect(described_class.new(:firefox).driver).to eq(driver_opts)
        end

        it 'does not create a service if a url is specified' do
          url = 'http://localhost:4444/wd/hub'
          @options = {url: url}
          expect(capabilities.driver).to be_nil
        end

        it 'handles all custom chromedriver options' do
          path = '/driver/path'
          driver_opts = {port: 1234,
                         adb_port: 5678,
                         log_path: 'log/path',
                         log_level: 'ALL',
                         # verbose: true, # (log-level=ALL),
                         # silent: true, # (log-level=OFF),
                         append_log: true,
                         replayable: true,
                         url_base: 'wd/url',
                         whitelisted_ips: 'http://google.com, http://yahoo.com'
          }

          @options = {driver: driver_opts}

          expect(Selenium::WebDriver::Chrome).to receive(:driver_path).and_return(path)
          expect(capabilities.driver).to eq(driver_opts)
        end
      end

      # TODO: If Selenium supports setting Service class directly, implement :service keyword parameter
      describe 'service arguments'

      describe 'http client arguments' do
        it 'defaults to Default Selenium class settings' do
          default_http_client = Selenium::WebDriver::Remote::Http::Default.new

          expect(capabilities.http_client[:open_timeout]).to eq default_http_client.open_timeout
          expect(capabilities.http_client[:read_timeout]).to eq default_http_client.read_timeout
        end

        it 'allows timeouts to be set' do
          @options = {http_client: {open_timeout: 10, read_timeout: 10}}

          expect(capabilities.http_client[:open_timeout]).to eq 10
          expect(capabilities.http_client[:read_timeout]).to eq 10
        end

        it 'creates http client Hash from Selenium Class' do
          http_client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 10, read_timeout: 10)

          @options = {http_client: http_client}
          expect(capabilities.http_client[:open_timeout]).to eq 10
          expect(capabilities.http_client[:read_timeout]).to eq 10
        end
      end

      describe 'proxy arguments' do
        it 'does not create proxy by default' do
          expect(capabilities.proxy).to be_nil
        end

        it 'builds Proxy Class from Hash' do
          proxy = Selenium::WebDriver::Proxy.new(type: :manual)
          @options = {proxy: {type: :manual}}

          expect(capabilities.proxy[:type]).to eql :manual
        end

        it 'builds accepts Selenium Proxy class' do
          proxy = Selenium::WebDriver::Proxy.new(type: :manual)
          @options = {proxy: proxy}

          expect(capabilities.proxy[:type]).to eql :manual
        end
      end

      describe 'url' do
        it 'does not create default url' do
          expect(capabilities.url).to be_nil
        end

        it 'uses remote if url is specified' do
          url = 'http://localhost:4444/wd/hub'
          @options = {url: url}
          expect(capabilities.url).to eq url
        end
      end

      describe 'listener' do
        it 'does not create default listener' do
          expect(capabilities.listener).to be_nil
        end

        it 'accepts listener argument' do
          listener = Selenium::WebDriver::Support::AbstractEventListener.new
          @options = {listener: listener}

          expect(capabilities.listener).to be_a(listener.class)
        end
      end

      describe 'standard w3c options' do
        it 'does not set default values for defined options' do
          expect(capabilities.browser_version).to be_nil
          expect(capabilities.platform_name).to be_nil
          expect(capabilities.accept_insecure_certs).to be_nil
          expect(capabilities.page_load_strategy).to be_nil
          expect(capabilities.proxy).to be_nil
          expect(capabilities.set_window_rect).to be_nil
          expect(capabilities.timeouts).to be_nil
          expect(capabilities.unhandled_prompt_behavior).to be_nil
        end

        it 'allows defined options to be set' do
          @options = {browser_version: '47',
                      platform_name: 'foo',
                      accept_insecure_certs: true,
                      page_load_strategy: 'eager',
                      set_window_rect: false,
                      unhandled_prompt_behavior: "ignore"}

          expect(capabilities.browser_version).to eq '47'
          expect(capabilities.platform_name).to eq 'foo'
          expect(capabilities.accept_insecure_certs).to eq true
          expect(capabilities.page_load_strategy).to eq 'eager'
          expect(capabilities.set_window_rect).to eq false
          expect(capabilities.unhandled_prompt_behavior).to eq "ignore"
        end

        it 'allows timeouts to be set' do
          timeouts = {implicit: 1,
                      page_load: 600_000,
                      script: 600_000}
          @options = {timeouts: timeouts}

          timeouts = capabilities.timeouts
          expect(timeouts).to be_a(Hash)
          expect(timeouts[:implicit]).to eq 1
          expect(timeouts[:page_load]).to eq 600000
          expect(timeouts[:script]).to eq 600000
        end

        it 'checks type of options' do
          Watir::Capabilities::W3C_OPTIONS.keys.each do |key|
            msg = /Incorrect Type for #{key}, expected one of \[.*\], but received Regexp/
            expect { described_class.new(key => /Unsupported Class/) }.to raise_exception(TypeError, msg)
          end
        end

        it 'accepts Selenium Options Class' do
          options = {browser_version: '47',
                     platform_name: 'foo',
                     accept_insecure_certs: true,
                     page_load_strategy: 'eager',
                     set_window_rect: false,
                     unhandled_prompt_behavior: 'ignore'}

          chrome_options = Selenium::WebDriver::Chrome::Options.new(options)
          @options = {chrome: chrome_options}

          expect(capabilities.browser_version).to eq '47'
          expect(capabilities.platform_name).to eq 'foo'
          expect(capabilities.accept_insecure_certs).to eq true
          expect(capabilities.page_load_strategy).to eq 'eager'
          expect(capabilities.set_window_rect).to eq false
          expect(capabilities.unhandled_prompt_behavior).to eq "ignore"
        end

        it 'accepts Selenium Capabilities Class as desired_capabilities' do
          options = {browser_version: '47',
                     platform_name: 'foo',
                     accept_insecure_certs: true,
                     page_load_strategy: 'eager',
                     set_window_rect: false,
                     unhandled_prompt_behavior: "ignore"}

          caps = Selenium::WebDriver::Remote::Capabilities.chrome(options)
          @options = {desired_capabilities: caps}

          expect(capabilities.browser_version).to eq '47'
          expect(capabilities.platform_name).to eq 'foo'
          expect(capabilities.accept_insecure_certs).to eq true
          expect(capabilities.page_load_strategy).to eq 'eager'
          expect(capabilities.set_window_rect).to eq false
          expect(capabilities.unhandled_prompt_behavior).to eq "ignore"
        end

        it 'defined options take precedence over Selenium Capabilities' do
          caps = Selenium::WebDriver::Remote::Capabilities.chrome(unhandled_prompt_behavior: "ignore")
          @options = {desired_capabilities: caps, unhandled_prompt_behavior: "dismiss"}

          expect(capabilities.unhandled_prompt_behavior).to eq "dismiss"
        end

        # TODO: implement this the way Selenium does it
        xit 'accepts desired capabilities with a Hash' do
          se_caps = {browser_name: 'chrome', browser_version: '68', platform_name: 'Windows'}
          expected_capabilities = Selenium::WebDriver::Remote::Capabilities.new(se_caps)

          caps = described_class.new(desired_capabilities: se_caps)

          expect(caps.capabilities).to eq expected_capabilities
        end
      end

      context 'when Chrome' do
        it 'Builds from Browser Options for' do
          browser_options = {# http://peter.sh/experiments/chromium-command-line-switches/
                             args: ['disable-infobars', 'remote-debugging-port=8181', 'incognito', 'window-size=400,400',
                                    'window-position=400,400'],
                             # Path to the Chrome executable
                             binary: '',
                             # base-64 encoded packed Chrome extensions
                             extensions: ['foo.crx', 'bar.crx'],
                             # I can't get anything to work with this
                             local_state: {},
                             # Docs: https://src.chromium.org/viewvc/chrome/trunk/src/chrome/common/pref_names.cc
                             # Common: https://www.chromium.org/administrators/configuring-other-preferences
                             prefs: {download: {prompt_for_download: false,
                                                default_directory: '/path/to/dir'},
                                     bookmark_bar: {show_on_all_tabs: true}},
                             # Browser stays open after chromedriver process is ended; useful for debugging
                             detach: true,
                             # If a browser is created with an arg "remote-debugging-port=8181", this will connect to it
                             debugger_address: '127.0.0.1:8181',
                             # List of Chrome command line switches to exclude that ChromeDriver uses by default
                             # I could not find any useful examples
                             exclude_switches: [],
                             # Linux Only
                             mini_dump_path: '',
                             mobile_emulation: {device_name: 'Pixel 2'},
                             perfLoggingPrefs: {enableNetwork: true,
                                                enablePage: true,
                                                traceCategories: '',
                                                bufferUsageReportingInterval: 1000},
                             window_types: []}
          @options = {chrome: browser_options}

          expect(capabilities.browser_options).to eq(browser_options)
        end

        it 'accepts Selenium Options Class' do
          options = {args: ['disable-infobars', 'remote-debugging-port=8181', 'incognito', 'window-size=400,400',
                            'window-position=400,400'],
                     # Path to the Chrome executable
                     binary: '',
                     extensions: ['foo.crx', 'bar.crx'],
                     # base-64 encoded packed Chrome extensions
                     encoded_extensions: [],
                     # Docs: https://src.chromium.org/viewvc/chrome/trunk/src/chrome/common/pref_names.cc
                     # Common: https://www.chromium.org/administrators/configuring-other-preferences
                     prefs: {download: {prompt_for_download: false,
                                        default_directory: '/path/to/dir'},
                             bookmark_bar: {show_on_all_tabs: true}},
                     options: {detach: true},
                     emulation: {device_name: 'Pixel 2'}}

          chrome_options = Selenium::WebDriver::Chrome::Options.new(options)
          @options = {chrome: chrome_options}

          expect(capabilities.options).to eq chrome_options

          expect(capabilities.browser_version).to eq '47'
          expect(capabilities.platform_name).to eq 'foo'
          expect(capabilities.accept_insecure_certs).to eq true
          expect(capabilities.page_load_strategy).to eq 'eager'
          expect(capabilities.set_window_rect).to eq false
          expect(capabilities.unhandled_prompt_behavior).to eq "ignore"
        end


      end

      context 'when IE'
      context 'when Edge'
      context 'when Safari'
      context 'when Firefox'
    end


    describe 'old' do

      context 'more' do

        it 'chrome options' do
          default_options = Selenium::WebDriver::Chrome::Options.new

          expect(capabilities.options.as_json).to eq default_options.as_json
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
        it 'Options class' do
          options = Selenium::WebDriver::Chrome::Options.new

          caps = described_class.new(options: options)

          expect(caps.options).to eql options
        end

        it 'Profile' do
          profile = Selenium::WebDriver::Chrome::Profile.new(profile_directory)
          profile.add_extension(extension_path)

          caps = described_class.new(profile: profile)

          expect(caps.profile).to eql profile
        end
      end

      context 'with Selenium Classes and parameters' do
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
      end

      context 'Builds Selenium Objects' do
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

        it 'builds Profile Class' do
          profile_path = '/path/to/profile'
          extension_path = '/path/to/extension'

          expected_profile = Selenium::WebDriver::Chrome::Profile.new(profile_path)
          expected_profile.add_extension(extension_path)

          capabilities = described_class.new(profile: profile_path, extensions: [extension_path])

          expect(capabilities.profile).to eq(expected_profile)
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