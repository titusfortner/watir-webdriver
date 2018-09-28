module Watir
  module Locators
    class TextField
      class SelectorBuilder
        class XPath < Element::SelectorBuilder::XPath
          def add_predicates(_scope_tag_name = nil)
            input_attr_exp = attribute_expression
            xpath = "[(not(@type) or (#{negative_type_expr}))"
            xpath << " and #{input_attr_exp}" unless input_attr_exp.empty?
            xpath << ']'
          end

          def add_tag_name
            @selector[:tag_name] = 'input'
            super
          end

          def lhs_for(key)
            key.to_s == 'text' ? '@value' : super
          end

          private

          def negative_type_expr
            Watir::TextField::NON_TEXT_TYPES.map { |type|
              format('%s!=%s', XpathSupport.downcase('@type'), type.inspect)
            }.join(' and ')
          end
        end
      end
    end
  end
end
