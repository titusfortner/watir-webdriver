module Watir
  module Locators
    class TextField
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          # TODO: Consider adding to the superclass an overridable method for adding subclass specific methods
          def build(selector)
            index = selector.delete(:index)
            xpath = super[:xpath]
            xpath << type_string(@selector.delete(:type))

            xpath = index ? add_index(xpath, index) : xpath

            @selector.merge! @requires_matches

            {xpath: xpath}
          end

          def text_string
            return super if @adjacent

            @requires_matches[:text] = @selector.delete(:text) if @selector.key?(:text)

          end

          def tag_string
            @selector[:tag_name] = 'input' unless @adjacent
            super
          end

          def use_index?
            false
          end

          def type_string(type)
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
