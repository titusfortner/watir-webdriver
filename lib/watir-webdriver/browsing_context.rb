# encoding: utf-8
module Watir

  #
  # For keeping track of nested browsing contexts as described here:
  # http://www.w3.org/TR/html5/browsers.html#nested-browsing-contexts

  # This allows for switching between contexts as described here:
  # http://w3c.github.io/webdriver/webdriver-spec.html#switching-frames
  #

  class BrowsingContext

    def initialize(context)
      @context = context
      case @context
      when Browser
        @parent = nil
      when IFrame
        @parent = context.browsing_context
      else
        raise ArgumentError, "#{context.class} is not a valid context type"
      end
    end

    def switch_to
      case @context
      when IFrame
        begin
          wd_element = @context.wd # Recursive call
          @context.driver.switch_to.frame wd_element
        rescue Selenium::WebDriver::Error::NoSuchFrameError
          raise Exception::UnknownFrameException
        end
      when Browser
        @context.driver.switch_to.default_content
      else
        raise ArgumentError "#{@context.class} is not an IFrame"
      end
      @top_element = @context.driver.first(css: '*')
    end

    def top_level?
      @parent.nil?
    end

    def in_context?
      return false if @top_element.nil? # Have never switched into context
      @top_element
      true
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      false
    end

    def switch_to_parent
      @context.driver.switch_to.parent_frame
    end

  end
end