module Watir
  module ElementCall
    private

    def wait_for_exists
      return assert_exists unless Watir.relaxed_locate?
      return if located? # Performance shortcut

      begin
        @query_scope.wait_for_exists unless @query_scope.is_a? Browser
        wait_until(element_reset: true, &:exists?)
      rescue Wait::TimeoutError
        msg = "timed out after #{Watir.default_timeout} seconds, waiting for #{inspect} to be located"
        raise unknown_exception, msg
      end
    end

    def wait_for_present
      p = present?
      return p if !Watir.relaxed_locate? || p

      begin
        @query_scope.wait_for_present unless @query_scope.is_a? Browser
        wait_until(&:present?)
      rescue Wait::TimeoutError
        msg = "element located, but timed out after #{Watir.default_timeout} seconds, " \
              "waiting for #{inspect} to be present"
        raise unknown_exception, msg
      end
    end

    def wait_for_enabled
      return assert_enabled unless Watir.relaxed_locate?

      wait_for_exists
      return unless [Input, Button, Select, Option].any? { |c| is_a? c } || @content_editable
      return if enabled?

      begin
        wait_until(&:enabled?)
      rescue Wait::TimeoutError
        raise_disabled
      end
    end

    def wait_for_writable
      wait_for_enabled
      unless Watir.relaxed_locate?
        raise_writable unless !respond_to?(:readonly?) || !readonly?
      end

      return if !respond_to?(:readonly?) || !readonly?

      begin
        wait_until { !respond_to?(:readonly?) || !readonly? }
      rescue Wait::TimeoutError
        raise_writable
      end
    end

    def assert_enabled
      raise ObjectDisabledException, "object is disabled #{inspect}" unless element_call { @element.enabled? }
    end

    def raise_present
      message = "element located, but timed out after #{Watir.default_timeout} seconds, " \
                               "waiting for #{inspect} to be present"
      raise unknown_exception, message
    end

    def raise_disabled
      message = "element present, but timed out after #{Watir.default_timeout} seconds, " \
                "waiting for #{inspect} to be enabled"
      raise ObjectDisabledException, message
    end

    def raise_writable
      message = "element present and enabled, but timed out after #{Watir.default_timeout} seconds, " \
                "waiting for #{inspect} to not be readonly"
      raise ObjectReadOnlyException, message
    end

    # TODO: replace with Watir::Executor when implemented
    def element_call(precondition = nil, &block)
      caller = caller_locations(1, 1)[0].label
      already_locked = Wait.timer.locked?
      Wait.timer = Wait::Timer.new(timeout: Watir.default_timeout) unless already_locked

      begin
        check_condition(precondition, caller)
        Watir.logger.debug "-> `Executing #{inspect}##{caller}`"
        yield
      rescue unknown_exception => ex
        element_call(:wait_for_exists, &block) if precondition.nil?
        msg = ex.message
        msg += '; Maybe look in an iframe?' if @query_scope.iframe.exists?
        custom_attributes = @locator.nil? ? [] : selector_builder.custom_attributes
        unless custom_attributes.empty?
          msg += "; Watir treated #{custom_attributes} as a non-HTML compliant attribute, ensure that was intended"
        end
        raise unknown_exception, msg
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        reset!
        retry
      rescue Selenium::WebDriver::Error::ElementNotVisibleError, Selenium::WebDriver::Error::ElementNotInteractableError
        raise_present unless Wait.timer.remaining_time.positive?
        raise_present unless %i[wait_for_present wait_for_enabled wait_for_writable].include?(precondition)
        retry
      rescue Selenium::WebDriver::Error::InvalidElementStateError
        raise_disabled unless Wait.timer.remaining_time.positive?
        raise_disabled unless %i[wait_for_present wait_for_enabled wait_for_writable].include?(precondition)
        retry
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise NoMatchingWindowFoundException, 'browser window was closed'
      ensure
        Watir.logger.debug "<- `Completed #{inspect}##{caller}`"
        Wait.timer.reset! unless already_locked
      end
    end

    def check_condition(condition, caller)
      Watir.logger.debug "<- `Verifying precondition #{inspect}##{condition} for #{caller}`"
      begin
        condition.nil? ? assert_exists : send(condition)
        Watir.logger.debug "<- `Verified precondition #{inspect}##{condition || 'assert_exists'}`"
      rescue unknown_exception
        raise unless condition.nil?

        Watir.logger.debug "<- `Unable to satisfy precondition #{inspect}##{condition}`"
        check_condition(:wait_for_exists, caller)
      end
    end
  end # JSExecution
end # Watir
