module Watir
  module Locators
    class TextField
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          # This is special because text locator is the value
          def text_string
            return super if @adjacent

            @selector[:value] = @selector.delete(:text) if @selector.key?(:text)

            # No this doesn't really belong here, but it works for now
            create_type_string(@selector.delete(:type))
          end

          def tag_string
            @selector[:tag_name] = 'input' unless @adjacent
            super
          end

          def use_index?
            false
          end

          def create_type_string(type)
            if type.eql?(true)
              "[#{negative_type_text}]"
            elsif Watir::TextField::NON_TEXT_TYPES.include?(type)
              msg = "TextField Elements can not be located by type: #{type}"
              raise LocatorException, msg
            elsif type.nil?
              "[not(@type) or (#{negative_type_text})]"
            else
              "[#{process_attribute(:type, type)}]"
            end
          end

          def negative_type_text
            Watir::TextField::NON_TEXT_TYPES.map { |type|
              "#{lhs_for(:type)}!=#{XpathSupport.escape type}"
            }.join(' and ')
          end
        end
      end
    end
  end
end
