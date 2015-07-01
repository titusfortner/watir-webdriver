require 'forwardable'
require 'watir-webdriver/wait/timer'

module Watir
  module Wait

    class TimeoutError < StandardError ; end

    INTERVAL = 0.1


    class << self

      #
      # @!attribute timer
      #   Access Watir timer implementation in use.
      #   @see Timer
      #   @return [#wait]
      #

      attr_writer :timer

      def timer
        @timer ||= Timer.new
      end

      #
      # Waits until the block evaluates to true or times out.
      #
      # @example
      #   Watir::Wait.until { browser.text_field(name: "new_user_first_name").visible? }
      #
      # @param [Fixnum] timeout How long to wait in seconds
      # @param [String] message Message to raise if timeout is exceeded
      # @yield block
      # @raise [TimeoutError] if timeout is exceeded
      #

      def until(timeout = nil, message = nil)
        timeout ||= Watir.default_timeout
        run_with_timer(timeout) { return true if yield(self) }
        raise TimeoutError, message_for(timeout, message)
      end

      #
      # Wait while the block evaluates to true or times out.
      #
      # @example
      #   Watir::Wait.while { browser.text_field(name: "abrakadbra").present? }
      #
      # @param [Fixnum] timeout How long to wait in seconds
      # @param [String] message Message to raise if timeout is exceeded
      # @yield block
      # @raise [TimeoutError] if timeout is exceeded
      #

      def while(timeout = nil, message = nil)
        timeout ||= Watir.default_timeout
        run_with_timer(timeout) { return unless yield(self) }
        raise TimeoutError, message_for(timeout, message)
      end

      private

      def message_for(timeout, message)
        err = "timed out after #{timeout} seconds"
        err << ", #{message}" if message

        err
      end

      def run_with_timer(timeout, &block)
        if timeout == 0
          block.call
        else
          timer.wait(timeout) do
            block.call
            sleep INTERVAL
          end
        end
      end

    end # self
  end # Wait

  module Waitable

    #
    # Executes given block until it returns true or exceeds timeout.
    #
    # @example
    #   browser.wait_until(30, 'Element is not visible') {browser.text_field(:name => "new_user_first_name").visible?}
    #
    # @param [Fixnum] timeout How long to wait in seconds
    # @param [String] message Message to raise if timeout is exceeded
    # @yield block
    # @raise [TimeoutError] if timeout is exceeded
    #

    def wait_until(*args, &blk)
      Wait.until(*args, &blk)
    end

    #
    # Executes given block while it returns true or exceeds timeout.
    #
    # @example
    #   browser.wait_while(30, 'Element is still visible') {browser.text_field(:name => "new_user_first_name").visible?}
    #
    # @param [Fixnum] timeout How long to wait in seconds
    # @param [String] message Message to raise if timeout is exceeded
    # @yield block
    # @raise [TimeoutError] if timeout is exceeded
    #

    def wait_while(*args, &blk)
      Wait.while(*args, &blk)
    end

    #
    # Execute the block once, bypassing execution of default wait_for_exists and wait_for_present methods
    #
    # @example
    #   browser.without_waiting {browser.text_field(:name => "new_user_first_name").visible?}
    #

    def without_waiting
      original_timeout = @default_timeout
      @default_timeout = 0
      return_value = yield
      @default_timeout = original_timeout
      return_value
    end

  end

  #
  # Wraps an Element so that any subsequent method calls are
  # put on hold until the element is present (exists and is visible) on the page.
  #

  class WhenPresentDecorator
    extend Forwardable

    ELEMENT_ACTIONS = [:set, :append, :clear, :click, :double_click, :right_click, :send_keys, :focus, :focused?, :submit]
    def_delegator :@element, :present?

    def initialize(element, timeout, message = nil)
      @element = element
      @timeout = timeout
      @message = message
    end

    def respond_to?(*args)
      @element.respond_to?(*args)
    end

    def method_missing(m, *args, &block)
      unless @element.respond_to?(m)
        raise NoMethodError, "undefined method `#{m}' for #{@element.inspect}:#{@element.class}"
      end

      Watir::Wait.until(@timeout, @message) { @element.present? }


      if @timeout >= Watir.default_timeout && @timeout != 0 && ELEMENT_ACTIONS.include?(m)
        warn "#when_present might be unnecessary for #{@element.send :selector_string}; elements now automatically wait when taking action - #{m}"
      end

      @element.__send__(m, *args, &block)
    end
  end # WhenPresentDecorator

  #
  # Convenience methods for things that eventually become present.
  #
  # Includers should implement a public #present? and a (possibly private) #selector_string method.
  #

  module EventuallyPresent
    #
    # Waits until the element is present.
    #
    # @example
    #   browser.text_field(name: "new_user_first_name").when_present.click
    #   browser.text_field(name: "new_user_first_name").when_present { |field| field.set "Watir" }
    #   browser.text_field(name: "new_user_first_name").when_present(60).text
    #
    # @param [Fixnum] timeout seconds to wait before timing out
    #
    # @see Watir::Wait
    # @see Watir::Element#present?
    #

    def when_present(timeout = nil)
      timeout ||= Watir.default_timeout
      message = "waiting for #{selector_string} to become present"

      if block_given?
        Watir::Wait.until(timeout, message) { present? }
        yield self
      else
        WhenPresentDecorator.new(self, timeout, message)
      end
    end

    #
    # Waits until the element is present.
    #
    # @example
    #   browser.text_field(name: "new_user_first_name").wait_until_present
    #
    # @param [Fixnum] timeout seconds to wait before timing out
    #
    # @see Watir::Wait
    # @see Watir::Element#present?
    #

    def wait_until_present(timeout = nil)
      timeout ||= Watir.default_timeout
      message = "waiting for #{selector_string} to become present"
      Watir::Wait.until(timeout, message) { present? }
    end

    #
    # Waits while the element is present.
    #
    # @example
    #   browser.text_field(name: "abrakadbra").wait_while_present
    #
    # @param [Fixnum] timeout seconds to wait before timing out
    #
    # @see Watir::Wait
    # @see Watir::Element#present?
    #

    def wait_while_present(timeout = nil)
      timeout ||= Watir.default_timeout
      message = "waiting for #{selector_string} to disappear"
      Watir::Wait.while(timeout, message) { present? }
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      # it's not present
    end

  end # EventuallyPresent
end # Watir
