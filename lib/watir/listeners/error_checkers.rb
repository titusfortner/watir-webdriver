module Watir

  #
  # Error checks are blocks that run after certain browser events.
  # They are generally used to ensure application under test does not encounter
  # any error and are automatically executed after following events:
  #   1. Open URL.
  #   2. Refresh page.
  #   3. Click, double-click or right-click on element.
  #   4. Alert closing.
  #

  class ErrorChecks
    include Enumerable

    def initialize(listener)
      @listener = listener
      @list = []
    end

    #
    # Adds new Error check.
    #
    # @example
    #   browser.error_checks.add do |browser|
    #     browser.text.include?("Server Error") and puts "Application exception or 500 error!"
    #   end
    #   browser.goto "watir.github.io/404"
    #   "Application exception or 500 error!"
    #
    # @param [#call] error_check Object responding to call
    # @yield error_check block
    # @yieldparam [Watir::Browser]
    #

    def add(error_check = nil, &block)
      if block_given?
        @list << block
      elsif error_check.respond_to? :call
        @list << error_check
      else
        raise ArgumentError, "expected block or object responding to #call"
      end

      @listener.add_error_checker(error_check)
    end
    alias_method :<<, :add

    #
    # Deletes Error check.
    #
    # @example
    #   browser.error_checks.add do |browser|
    #     browser.text.include?("Server Error") and puts "Application exception or 500 error!"
    #   end
    #   browser.goto "watir.github.io/404"
    #   "Application exception or 500 error!"
    #   browser.error_checks.delete browser.error_checks[0]
    #   browser.refresh
    #

    def delete(error_check)
      @list.delete error_check
      @listener.delete_error_checker(error_check)
    end

    #
    # Executes a block without running error Error checks.
    #
    # @example
    #   browser.error_checks.without do |browser|
    #     browser.element(name: "new_user_button").click
    #   end
    #
    # @yield Block that is executed without Error checks being run
    # @yieldparam [Watir::Browser]
    #

    def without
      current_error_checks = @list.dup

      @list.each { |error_check| delete error_check}
      yield
      current_error_checks.each { |error_check| add error_check}

    ensure
      @list = current_error_checks
    end

    #
    # Returns number of Error checks.
    #
    # @example
    #   browser.error_checks.add { puts 'Some error_check.' }
    #   browser.error_checks.length
    #   #=> 1
    #
    # @return [Fixnum]
    #

    def length
      @list.length
    end
    alias_method :size, :length

    #
    # Gets the Error check at the given index.
    #
    # @param [Fixnum] index
    # @return [#call]
    #

    def [](index)
      @list[index]
    end

  end # ErrorChecks
end # Watir
