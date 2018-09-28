module Watir
  module Locators
    class Element
      class SelectorBuilder
        class XPath
          include Exception

          CAN_NOT_BUILD = %i[visible visible_text visible_label]
          # Regular expressions that can be reliably converted to xpath `contains`
          # expressions in order to optimize the locator.
          LITERAL_REGEXP = /([^\[\]\\^$.|?*+(){}]*(?![\*\?\{]))/
          CONVERTIBLE_REGEXP = /
            \A
              \^?                        # start
              #{LITERAL_REGEXP.source}   # leading literal characters
              (?:
                [^|]*?                   # do not try to convert expressions with alternates
                (?<!\\)                  # skip metacharacters - ie has preceding slash
                #{LITERAL_REGEXP.source} # trailing literal characters
              )*
              \$?                        # end
            \z
          /x

          def build(selector, scope_tag_name = nil)
            @selector = selector

            requires_matches = (@selector.keys & CAN_NOT_BUILD).each_with_object({}) do |key, hash|
              hash[key] = @selector.delete(key)
            end

            index = @selector.delete(:index)
            adjacent = @selector.delete :adjacent
            xpath = adjacent.nil? ? default_start : process_adjacent(adjacent)

            xpath << add_tag_name
            xpath << add_class_predicates if @selector.key?(:class)
            requires_matches[:class] = @selector.delete(:class) if @selector.key?(:class)

            xpath << add_predicates(scope_tag_name)
            xpath << add_attribute_predicates if convert_regexp_to_contains?

            @selector.merge!(requires_matches)

            xpath = if adjacent && index
                      # TODO: write test to make sure this works with complex regular expressions
                      "#{xpath}[#{index + 1}]"
                    elsif index&.positive? && @selector.empty?
                      to_index = xpath.empty? ? '' : "(#{xpath})"
                      "#{to_index}[#{index + 1}]"
                    else
                      @selector[:index] = index if index&.positive? || index&.negative?
                      xpath
                    end

            {xpath: xpath}
          end

          def simple_regexp?(regexp)
            regexp.is_a?(Regexp) &&
                regexp.source.match(CONVERTIBLE_REGEXP)&.captures&.reject(&:empty?)&.first == regexp.source
          end

          protected

          def default_start
            './/*'
          end

          def process_adjacent(adjacent)
            case adjacent
            when :ancestor
              './ancestor::*'
            when :preceding
              './preceding-sibling::*'
            when :following
              './following-sibling::*'
            when :child
              './child::*'
            else
              raise LocatorException, "Unable to process adjacent locator with #{adjacent}"
            end
          end

          def add_tag_name
            tag_name = @selector.delete(:tag_name)
            if tag_name.is_a?(Regexp)
              "[contains(local-name(), #{tag_name.source})]"
            elsif tag_name.to_s.empty?
              ''
            else
              "[local-name()='#{tag_name}']"
            end
          end

          def add_predicates(_scope_tag_name = nil)
            element_attr_exp = attribute_expression
            element_attr_exp.empty? ? '' : "[#{element_attr_exp}]"
          end

          def attribute_expression
            @selector.map { |key, value|
              next if key == :class || value.is_a?(Regexp)

              locator_expression(key, value).tap { @selector.delete(key) }
            }.compact.join(' and ')
          end

          def locator_expression(key, value)
            if value.is_a?(Array)
              '(' + value.map { |v| equal_pair(key, v) }.join(' or ') + ')'
            elsif value.eql? true
              attribute_presence(key)
            elsif value.eql? false
              attribute_absence(key)
            else
              equal_pair(key, value)
            end
          end

          def equal_pair(key, value)
            if key == :label_element
              # we assume :label means a corresponding label element, not the attribute
              text = "normalize-space()=#{XpathSupport.escape value}"
              "(@id=//label[#{text}]/@for or parent::label[#{text}])"
            else
              "#{lhs_for(key)}=#{XpathSupport.escape value}"
            end
          end

          def attribute_presence(attribute)
            lhs_for(attribute)
          end

          def attribute_absence(attribute)
            "not(#{lhs_for(attribute)})"
          end

          def lhs_for(key)
            case key
            when :text
              'normalize-space()'
            # TODO: This is a bad hack, fix it
            when 'text'
              'text()'
            when String
              "@#{key}"
            when :href
              'normalize-space(@href)'
            when :type
              # type attributes can be upper case - downcase them
              # https://github.com/watir/watir/issues/72
              XpathSupport.downcase('@type')
            when ::Symbol
              "@#{key.to_s.tr('_', '-')}"
            else
              raise LocatorException, "Unable to build XPath using #{key}"
            end
          end

          def add_class_predicates
            if @selector[:class].is_a?(String) && @selector[:class].strip.include?(' ')
              dep = "Using the :class locator to locate multiple classes with a String value (i.e. \"#{value}\")"
              Watir.logger.deprecate dep,
                                     "Array (e.g. #{value.split})",
                                     ids: [:class_array]
            end

            @selector[:class] = [@selector[:class]].flatten
            predicates = []

            @selector[:class].dup.each do |value|
              if [TrueClass, FalseClass].include?(value.class)
                predicates << locator_expression(:class, value)
                @selector[:class].delete(value)
                break
              end

              predicate, remainder = class_predicate(value)
              predicates << predicate
              @selector[:class].delete(value) unless remainder
            end

            return '' if predicates.empty?

            @selector.delete(:class) if @selector[:class].empty?
            "[#{predicates.join(' and ')}]"
          end

          def class_predicate(value)
            return attribute_predicate(:class, value) if value.is_a?(Regexp)

            negate = value =~ /^!/ ? value.slice!(0) : nil
            klass = XpathSupport.escape " #{value} "
            "#{'not' if negate}(contains(concat(' ', @class, ' '), #{klass}))"
          end

          def convert_regexp_to_contains?
            true
          end

          def add_attribute_predicates(_scope_tag_name = nil)
            predicates = @selector.keys.each_with_object([]) do |key, array|
              predicate, remainder = attribute_predicate(key, @selector[key])
              next if predicate.nil?
              array << predicate
              @selector.delete(key) unless remainder
            end
            predicates.empty? ? '' : "[#{predicates.compact.join(' and ')}]"
          end

          def attribute_predicate(key, regexp)
            source = regexp.source
            return [nil, {key => regexp}] if regexp.casefold? || source.empty?

            negate = source =~ /^!/ ? source.shift : nil

            key = 'text' if key == :text
            lhs = lhs_for(key)

            if source.match(CONVERTIBLE_REGEXP)&.captures&.reject(&:empty?)&.first == source
              return "#{'not' if negate}(contains(#{lhs}, '#{regexp.source}'))"
            end

            # This is taking as much as it can before the first special character to do a better partial match
            # Note that the final character might be optional, so we can't use it
            captures = source.match(CONVERTIBLE_REGEXP)&.captures&.reject { |cap| cap.size < 2 }

            return [lhs, {key => regexp}] if captures.nil? || captures.empty?

            captures.map! do |literals|
              "(contains(#{lhs}, #{XpathSupport.escape(literals[0..-2])}))"
            end
            [captures, {key => regexp}]
          end
        end
      end
    end
  end
end
