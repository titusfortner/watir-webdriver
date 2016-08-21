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

    DOM_CHANGES = %w[navigate_to click context_click accept_alert dismiss_alert
                  double_click submit_element refresh]

    ERROR_CHECKS = DOM_CHANGES.map { |action| "after_#{action}" }

    def initialize(browser)
      @browser = browser
      @watir_actions = {}
    end

    def add_error_checker(action)
      ERROR_CHECKS.each do |listener_action|
        eval("#{listener_action}s") << action
      end
    end

    def delete_error_checker(action)
      ERROR_CHECKS.each do |listener_action|
        eval("#{listener_action}s").delete(action)
      end
    end

    # It needs to be an add and delete for Watir
    # Implementation need not be limited to Selenium calls

    # So what belongs in ErrorCheckers now?
    # It just holds


    def add(watir_method, action = nil, &block)
      action_array = @watir_actions[watir_method] ||= []
      if block_given?
        action_array << block
      elsif error_check.respond_to? :call
        action_array << action
      else
        raise ArgumentError, "expected block or object responding to #call"
      end
      @loaded = true
    end
    alias_method :<<, :add

    def loaded?
      @loaded
    end

    def find(watir_method)
      @watir_actions[watir_method] || []
    end

    def delete(listener_action, action)
    end

  end
end
