module Watir
  module Locators
    class TextArea
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          private

          # This is special because text locator is the value
          def text_string
            return super if @adjacent

            @selector[:value] = @selector.delete(:text) if @selector.key?(:text)
            ''
          end
        end
      end
    end
  end
end
