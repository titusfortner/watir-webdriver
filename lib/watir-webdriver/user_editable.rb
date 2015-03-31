module Watir
  module UserEditable

    #
    # Clear the element, the type in the given value.
    #
    # @param [String, Symbol] *args
    #

    def set(*args)
      clear
      element_call { @element.send_keys(*args) }
    end
    alias_method :value=, :set

    #
    # Appends the given value to the text in the text field.
    #
    # @param [String, Symbol] *args
    #

    def append(*args)
      original_value = element_call { @element.value } if args.size == 1 && args.first.is_a?(String)
      send_keys(*args)
      if original_value && element_call { @element.value } != "#{original_value}#{args.first}"
        set(*args)
      end
    end
    alias_method :<<, :append

    #
    # Clears the text field.
    #

    def clear
      assert_exists
      assert_writable
      element_call { @element.clear }
    end

  end # UserEditable
end # Watir
