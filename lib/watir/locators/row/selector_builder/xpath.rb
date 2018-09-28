module Watir
  module Locators
    class Row
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath

          def build(selector, scope_tag_name)
            @selector = selector

            index = @selector.delete(:index)

            wd_locator = super(@selector)

            @selector[:index] = index if index&.negative?
            index_xpath = index&.positive? ? "[#{index + 1}]" : ''

            attr_expr = wd_locator[:xpath]
            expressions = generate_expressions(scope_tag_name)
            expressions.map! { |e| "#{e}#{attr_expr}" } unless attr_expr.empty?
            xpath = "(#{expressions.join(' | ')})#{index_xpath}"

            {xpath: xpath}
          end

          def add_tag_name
            @selector.delete(:tag_name)
            ''
          end

          def default_start
            ''
          end

          private

          def generate_expressions(scope_tag_name)
            expressions = %w[./tr]
            return expressions if scope_tag_name.nil? || %w[tbody tfoot thead].include?(scope_tag_name)

            expressions + %w[./tbody/tr ./thead/tr ./tfoot/tr]
          end
        end
      end
    end
  end
end
