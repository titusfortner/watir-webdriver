module Watir
  module Locators
    class Button
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          def build(selector, scope_tag_name)
            @selector = selector
            @selector[:tag_name] = 'button'

            if @selector[:type].eql?(false)
              @selector.delete :type
              return super(@selector)
            end

            index = @selector.delete(:index)

            wd_locator = super(@selector)

            @selector[:index] = index if index&.negative?

            first = ".//*[local-name()='button']"
            common = wd_locator[:xpath].gsub(first, '')

            # TODO: Figure out why sometimes it doesn't have parenthesis
            if common[/\(\)\[/]
              common.gsub!('()', '')
              first = "(#{first})"
            end

            types = input_types(@selector[:type])
            type_text = types.empty? ? '' : "[#{types}]"

            button_xpath = "#{first}#{common}"
            input_xpath = "#{first.gsub('button', 'input')}#{type_text}#{common}"
            index_xpath = index&.positive? ? "[#{index + 1}]" : ''

            xpath = if @selector[:type].eql?(true)
                      "#{input_xpath}#{index_xpath}"
                    else
                      "(#{button_xpath} | #{input_xpath})#{index_xpath}"
                    end

            {xpath: xpath}
          end

          def input_types(type)
            return '' if type.eql? false
            types = [nil, true].include?(type) ? Watir::Button::VALID_TYPES : [type]
            types.map do |type|
              "#{XpathSupport.downcase '@type'}=#{XpathSupport.escape type}"
            end.compact.join(' or ')
          end

          # TODO: Remove this method once we remove value_button deprecation
          def attribute_predicate(key, value)
            return super unless key == :value
            "#{super(key, value)} or #{super(:text, value)}"
          end

          # TODO: Remove this method once we remove value_button deprecation
          def equal_pair(key, value)
            if key == :value
              Watir.logger.deprecate(':value locator key for finding button text', 'use :text', ids: ['value_button'])
              text = XpathSupport.escape(value)
              "(text()=#{text} or @value=#{text})"
            else
              super
            end
          end
        end
      end
    end
  end
end
