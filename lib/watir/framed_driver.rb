module Watir
  #
  # @api private
  #
  class FramedDriver
    def initialize(element, browser)
      @element = element
      @browser = browser
      @driver = browser.driver
    end

    def ==(other)
      wd == other.wd
    end
    alias eql? ==

    def send_keys(*args)
      switch!
      @driver.switch_to.active_element.send_keys(*args)
    end

    protected

    def wd
      @element
    end

    private

    def respond_to_missing?(meth)
      @driver.respond_to?(meth) || @element.respond_to?(meth)
    end

    def method_missing(meth, *args, &blk)
      if @driver.respond_to?(meth)
        switch!
        @driver.send(meth, *args, &blk)
      elsif @element.respond_to?(meth)
        @element.send(meth, *args, &blk)
      else
        super
      end
    end

    def switch!
      @driver.switch_to.frame @element
      @browser.default_context = false
    rescue Selenium::WebDriver::Error::NoSuchFrameError => e
      raise Exception::UnknownFrameException, e.message
    end
  end # FramedDriver
end # Watir
