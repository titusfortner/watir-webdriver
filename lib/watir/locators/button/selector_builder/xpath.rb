module Watir
  module Locators
    class Button
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          private

          def tag_string
            return super if @adjacent

            # Selector builder ignores tag name and builds for both button elements and input elements of type button
            @selector.delete(:tag_name)

            type = @selector.delete :type
            text = @selector.delete :text

            if type.nil? && text.is_a?(String)
              "[(local-name()='button' and normalize-space()='#{text}') or " \
"(local-name()='input' and (#{input_types}) and @value='#{text}')]"
            elsif type.nil? && XpathSupport.simple_regexp?(text)
              "[(local-name()='button' and contains(text(), '#{text.source}')) or " \
"(local-name()='input' and (#{input_types}) and contains(@value, '#{text.source}'))]"
            elsif type.nil? && text
              @requires_matches[:text] = text
              "[(local-name()='button' and text()) or (local-name()='input' and (#{input_types}) and @value)]"
            elsif type.nil?
              "[local-name()='button' or (local-name()='input' and (#{input_types}))]"
            elsif type.eql?(false)
              @selector[:type] = false
              "[local-name()='button']"
            elsif type.eql?(true)
              @selector[:type] = true
              "[local-name()='button' or (local-name()='input' and (#{input_types}))]"
            else
              @selector[:text] = text if text
              "[local-name()='button' or local-name()='input'][#{input_types(type)}]"
            end
          end

          # value locator needs to match input value, button text or button value
          def text_string
            return super if @adjacent

            # :text locator is already dealt with in #tag_name_string
            value = @selector.delete(:value)

            case value
            when nil
              ''
            when Regexp
              res = "[#{predicate_conversion(:contains_text, value)} or #{predicate_conversion(:value, value)}]"
              if @requires_matches.key?(:contains_text)
                @requires_matches[:value] = @requires_matches.delete(:contains_text)
              end
              res
            else
              "[#{predicate_expression(:text, value)} or #{predicate_expression(:value, value)}]"
            end
          end

          def use_index?
            false
          end

          def input_types(type = nil)
            types = if type.eql?(nil)
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
