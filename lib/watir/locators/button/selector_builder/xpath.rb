module Watir
  module Locators
    class Button
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          private

          def tag_string
            return super if @adjacent

            @selector.delete(:tag_name)

            type = @selector.delete :type

            if type
              "[(local-name()='input' and #{input_types(type)})]"
            elsif type.nil?
              "[local-name()='button' or (local-name()='input' and #{input_types(type)})]"
            else
              "[local-name()='button']"
            end
          end

          # This is special because text locator for buttons match text or value
          def text_string
            return super if @adjacent

            text = @selector.delete(:text) || @selector.delete(:value)

            case text
            when nil
              ''
            when Regexp
              res = "[#{predicate_conversion(:contains_text, text)} or #{predicate_conversion(:value, text)}]"
              if @requires_matches.key?(:contains_text)
                @requires_matches[:text] = @requires_matches.delete(:contains_text)
                @requires_matches.delete(:value)
              end
              res
            else
              "[#{predicate_expression(:text, text)} or #{predicate_expression(:value, text)}]"
            end
          end

          def use_index?
            false
          end

          def input_types(type)
            types = if [nil, true].include?(type)
                      Watir::Button::VALID_TYPES
                    elsif Watir::Button::VALID_TYPES.include?(type)
                      [type]
                    else
                      msg = "Button Elements can not be located by input type: #{type}"
                      raise LocatorException, msg
                    end
            types.map { |button_type|
              "#{XpathSupport.downcase '@type'}=#{XpathSupport.escape button_type}"
            }.compact.join(' or ')
          end
        end
      end
    end
  end
end
