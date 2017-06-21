module Watir
  module Locators
    class TextField
      class Validator < Element::Validator
        def validate(element, selector)
          # Don't need to validate the element if Watir builds the locator
          return element unless selector.key?(:xpath) || selector.key?(:css)
          return unless element.tag_name.downcase == 'input'

          element
        end
      end
    end
  end
end
