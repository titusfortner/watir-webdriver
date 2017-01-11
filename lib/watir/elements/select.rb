module Watir
  class Select < HTMLElement
    include Watir::Exception

    #
    # Clears all selected options.
    #

    def clear
      raise Error, "you can only clear multi-selects" unless multiple?

      options.each do |o|
        o.click if o.selected?
      end
    end

    #
    # Gets all the options in the select list
    #
    # @return [Watir::OptionCollection]
    #

    def options(*)
      super
    end

    #
    # Returns true if the select list has one or more options where text or label matches the given value.
    #
    # @param [String, Regexp] str_or_rx
    # @return [Boolean]
    #

    def include?(str_or_rx)
      options.to_a.any? do |e|
        str_or_rx === e.text || str_or_rx === e.label
      end
    end

    #
    # Select the option(s) whose text or label matches the given string.
    # If this is a multi-select and several options match the value given, all will be selected.
    #
    # @param [String, Regexp] str_or_rx
    # @raise [Watir::Exception::NoValueFoundException] if the value does not exist.
    # @return [String] The text of the option selected. If multiple options match, returns the first match.
    #

    def select(str_or_rx)
      select_by :text, str_or_rx
    end

    #
    # Selects the option(s) whose value attribute matches the given string.
    #
    # @see +select+
    #
    # @param [String, Regexp] str_or_rx
    # @raise [Watir::Exception::NoValueFoundException] if the value does not exist.
    # @return [String] The option selected. If multiple options match, returns the first match
    #

    def select_value(str_or_rx)
      select_by :value, str_or_rx
    end

    #
    # Returns true if any of the selected options' text or label matches the given value.
    #
    # @param [String, Regexp] str_or_rx
    # @raise [Watir::Exception::UnknownObjectException] if the options do not exist
    # @return [Boolean]
    #

    def selected?(str_or_rx)
      match_found = false

      options.each do |e|
        next unless str_or_rx === e.text || str_or_rx === e.label
        return true if e.selected?
        match_found = true
      end

      raise(UnknownObjectException, "Unable to locate option matching #{str_or_rx.inspect}") unless match_found

      false
    end

    #
    # Returns the value of the first selected option in the select list.
    # Returns nil if no option is selected.
    #
    # @return [String, nil]
    #

    def value
      o = options.to_a.find(&:selected?)
      o.value if o
    end


    #
    # Returns an array of currently selected options.
    #
    # @return [Array<Watir::Option>]
    #

    def selected_options
      options.to_a.select(&:selected?)
    end

    private

    def select_by(how, str_or_rx)
      found = nil
      begin
        Wait.until do
          case str_or_rx
          when String, Numeric, Regexp
            found = options(how => str_or_rx)
            found = options(label: str_or_rx) if found.to_a.empty?
          else
            raise TypeError, "expected String or Regexp, got #{str_or_rx.inspect}:#{str_or_rx.class}"
          end
          !found.to_a.empty?
        end
      rescue Wait::TimeoutError
        raise NoValueFoundException, "#{str_or_rx.inspect} not found in select list"
      end
      select_matching(found)
    end

    def select_matching(elements)
      elements = [elements.first] unless multiple?
      elements.each { |e| e.click unless e.selected? }
      elements.first.exist? ? elements.first.text : ''
    end

    def matches_regexp?(how, element, exp)
      case how
      when :text
        element.text =~ exp || element.label =~ exp
      when :value
        element.value =~ exp
      else
        raise Error, "unknown how: #{how.inspect}"
      end
    end
  end # Select

  module Container
    alias_method :select_list, :select
    alias_method :select_lists, :selects

    Watir.tag_to_class[:select_list] = Select
  end # Container
end # Watir
