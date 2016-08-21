# TODO - remove this when implemented in Selenium
module Selenium
  module WebDriver
    module Support
      class EventFiringBridge

        %i[accept_alert dismiss_alert double_click context_click
            submit_element refresh].each do |method|
          define_method(method) do |*args|
            dispatch(method, driver) { @delegate.send method, *args }
          end
        end

      end

      class AbstractEventListener
        def before_accept_alert(driver); end

        def before_dismiss_alert(driver); end

        def before_double_click(driver); end

        def before_context_click(driver); end

        def before_submit_element(element, driver); end

        def before_refresh(driver); end

        def after_accept_alert(driver); end

        def after_dismiss_alert(driver); end

        def after_double_click(driver); end

        def after_context_click(driver); end

        def after_submit_element(element, driver); end

        def after_refresh(driver); end
      end
    end
  end
end

module Watir
  class Listener < Selenium::WebDriver::Support::AbstractEventListener
    attr_reader :error_checks

    LISTENERS = Selenium::WebDriver::Support::AbstractEventListener.instance_methods(false)

    LISTENERS.each do |listener|
      define_method("#{listener}s") do |*_args|
        result = instance_variable_get("@#{listener}s")
        return result if result
        instance_variable_set("@#{listener}s", [])
      end

      define_method(listener) do |*_args|
        listeners = eval("#{listener}s")
        return if listeners.empty?
        browser_exists = listener != :after_quit && @browser.exist?
        eval("#{listener}s").each do |action|
          action.call(@browser) if browser_exists
        end
      end
    end

    def initialize(browser)
      @browser = browser
      @error_checks = ErrorChecks.new(self)
    end

    def add(listener_action, action = nil, &block)
      if block_given?
        eval("#{listener_action}s") << block
      elsif action.respond_to? :call
        eval("#{listener_action}s") << action
      else
        raise ArgumentError, "expected block or object responding to #call"
      end
    end

    alias_method :<<, :add

    def delete(listener_action, action)
      eval("#{listener_action}s").delete(action)
    end

  end
end
