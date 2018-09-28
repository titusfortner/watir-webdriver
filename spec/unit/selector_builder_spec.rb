require_relative 'unit_helper'

describe Watir::Locators::Element::SelectorBuilder do
  let(:attributes) { Watir::HTMLElement.attribute_list }
  let(:scope_tag_name) { nil }
  let(:selector_builder) { described_class.new(scope_tag_name, attributes) }

  def expect_built(selector, expected, remaining = {})
    built = selector_builder.build(selector)
    expect(built).to eq [expected, remaining]
  end

  describe '#build' do
    it 'builds with no locators provided' do
      selector = {}
      expected = {xpath: './/*'}

      expect_built(selector, expected)
    end

    context 'with single locator' do
      context 'with String values' do
        it 'tag name' do
          selector = {tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div']"}

          expect_built(selector, expected)
        end

        it 'xpath' do
          selector = {xpath: './/div]'}
          expected = selector.dup

          expect_built(selector, expected)
        end

        it 'css' do
          selector = {css: 'div'}
          expected = selector.dup

          expect_built(selector, expected)
        end

        it 'single class name' do
          selector = {class: 'foo'}
          expected = {xpath: ".//*[(contains(concat(' ', @class, ' '), ' foo '))]"}

          expect_built(selector, expected)
        end

        it 'attribute' do
          selector = {id: 'foo'}
          expected = {xpath: ".//*[@id='foo']"}

          expect_built(selector, expected)
        end

        it 'class name array' do
          selector = {class: %w[foo bar]}
          xpath = ".//*[(contains(concat(' ', @class, ' '), ' foo ')) and " \
"(contains(concat(' ', @class, ' '), ' bar '))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'text' do
          selector = {text: 'foo'}
          expected = {xpath: ".//*[normalize-space()='foo']"}

          expect_built(selector, expected)
        end
      end

      context 'with Simple Regexp values' do
        it 'tag name' do
          selector = {tag_name: /div/}
          expected = {xpath: './/*[contains(local-name(), div)]'}

          expect_built(selector, expected)
        end

        it 'single class name' do
          selector = {class: /foo/}
          expected = {xpath: ".//*[(contains(@class, 'foo'))]"}

          expect_built(selector, expected)
        end

        it 'attribute' do
          selector = {id: /foo/}
          expected = {xpath: ".//*[(contains(@id, 'foo'))]"}

          expect_built(selector, expected)
        end

        it 'class name array same' do
          selector = {class: [/foo/, /bar/]}
          xpath = ".//*[(contains(@class, 'foo')) and (contains(@class, 'bar'))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'class name array mixed' do
          selector = {class: ['foo', /bar/]}
          xpath = ".//*[(contains(concat(' ', @class, ' '), ' foo ')) and (contains(@class, 'bar'))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'text' do
          selector = {text: /foo/}
          expected = {xpath: ".//*[(contains(text(), 'foo'))]"}

          expect_built(selector, expected)
        end
      end
    end

    context 'with tag name and single locator' do
      xcontext "Ideal Behavior" do
        it 'xpath' do
          selector = {xpath: ".//*[@id='foo']", tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][@id='foo']"}

          expect_built(selector, expected)
        end

        it 'css' do
          selector = {css: '.bar', tag_name: 'div'}
          expected = {css: 'div.bar'}

          expect_built(selector, expected)
        end
      end

      context "With String Values" do
        it 'css' do
          selector = {css: '.bar', tag_name: 'div'}
          expected = {css: '.bar'}
          remaining = {tag_name: 'div'}

          expect_built(selector, expected, remaining)
        end

        it 'xpath' do
          selector = {xpath: ".//*[@id='foo']", tag_name: 'div'}
          expected = {xpath: ".//*[@id='foo']"}
          remaining = {tag_name: 'div'}

          expect_built(selector, expected, remaining)
        end

        it 'single class name' do
          selector = {class: 'foo', tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][(contains(concat(' ', @class, ' '), ' foo '))]"}

          expect_built(selector, expected)
        end

        it 'attribute' do
          selector = {id: 'foo', tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][@id='foo']"}

          expect_built(selector, expected)
        end

        it 'class name array' do
          selector = {class: %w[foo bar], tag_name: 'div'}
          xpath = ".//*[local-name()='div'][(contains(concat(' ', @class, ' '), ' foo '))" \
        " and (contains(concat(' ', @class, ' '), ' bar '))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'text' do
          selector = {text: 'foo', tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][normalize-space()='foo']"}

          expect_built(selector, expected)
        end
      end

      context "With Simple Regexp Values" do
        it 'single class name' do
          selector = {class: /foo/, tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][(contains(@class, 'foo'))]"}

          expect_built(selector, expected)
        end

        it 'attribute' do
          selector = {id: /foo/, tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][(contains(@id, 'foo'))]"}

          expect_built(selector, expected)
        end

        it 'class name array same' do
          selector = {class: [/foo/, /bar/], tag_name: 'div'}
          xpath = ".//*[local-name()='div'][(contains(@class, 'foo')) and (contains(@class, 'bar'))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'class name array mixed' do
          selector = {class: [/foo/, 'bar'], tag_name: 'div'}
          xpath = ".//*[local-name()='div'][(contains(@class, 'foo')) and (contains(concat(' ', @class, ' '), ' bar '))]"
          expected = {xpath: xpath}

          expect_built(selector, expected)
        end

        it 'text' do
          selector = {text: /foo/, tag_name: 'div'}
          expected = {xpath: ".//*[local-name()='div'][(contains(text(), 'foo'))]"}

          expect_built(selector, expected)
        end
      end
    end

    context 'with multiple attributes' do
      it 'as Strings' do
        selector = {id: 'foo', name: 'bar'}
        expected = {xpath: ".//*[@id='foo' and @name='bar']"}

        expect_built(selector, expected)
      end

      it 'as Regexp' do
        selector = {id: /foo/, name: /bar/}
        expected = {xpath: ".//*[(contains(@id, 'foo')) and (contains(@name, 'bar'))]"}

        expect_built(selector, expected)
      end

      it 'as mixed' do
        selector = {id: 'foo', name: /bar/}
        expected = {xpath: ".//*[@id='foo'][(contains(@name, 'bar'))]"}

        expect_built(selector, expected)
      end
    end

    it 'presense of attribute'
    it 'absence of attribute'
    context 'adjacent'

    context 'with locators that can not be directly translated' do
      it ':index' do
        selector = {tag_name: 'div', index: 4}
        expected = {xpath: "(.//*[local-name()='div'])[5]"}

        expect_built(selector, expected)
      end

      it 'complicated Regexp' do
        selector = {foo: /^c$/}
        expected = {xpath: ".//*[@foo]"}
        remaining = {foo: /^c$/}

        expect_built(selector, expected, remaining)
      end
    end
  end
end

describe Watir::Locators::Button::SelectorBuilder do
  let(:attributes) { Watir::Button.attribute_list }
  let(:scope_tag_name) { nil }
  let(:selector_builder) { described_class.new(scope_tag_name, attributes) }

end


