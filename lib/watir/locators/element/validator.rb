module Watir
  module Locators
    class Element
      class Validator
        def validate(element, selector)
          # Don't need to validate the element if Watir builds the locator
          return element unless selector.key?(:xpath) || selector.key?(:css)

          selector_tag_name = selector[:tag_name]
          element_tag_name = element.tag_name.downcase

          if selector_tag_name
            return unless selector_tag_name === element_tag_name
          end

          element
        end
      end
    end
  end
end
