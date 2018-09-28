module Watir
  module Locators
    class Cell
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          def build(selector, _scope_tag_name = nil)
            @selector = selector

            index = @selector.delete(:index)

            wd_locator = super(@selector)

            @selector[:index] = index if index&.negative?
            index_xpath = index&.positive? ? "[#{index + 1}]" : ''

            attr_expr = wd_locator[:xpath]
            index = attr_expr.match(/\[\d+\]/).to_s
            attr_expr.gsub!(index, '')

            expressions = %w[./th ./td]
            expressions.map! { |e| "#{e}#{attr_expr}" } unless attr_expr.empty?
            xpath = "(#{expressions.join(' | ')})#{index_xpath}"

            {xpath: xpath}
          end

          def default_start
            ''
          end

          def add_tag_name
            @selector.delete(:tag_name)
            ''
          end
        end
      end
    end
  end
end
