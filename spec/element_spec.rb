require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Watir::Element do

  before :each do
    browser.goto(WatirSpec.url_for("forms_with_input_elements.html"))
  end

  describe '#present?' do
    before do
      browser.goto(WatirSpec.url_for("wait.html"))
    end

    it 'returns true if the element exists and is visible' do
      expect(browser.div(:id, 'foo')).to be_present
    end

    it 'returns false if the element exists but is not visible' do
      expect(browser.div(:id, 'bar')).to_not be_present
    end

    it 'returns false if the element does not exist' do
      expect(browser.div(:id, 'should-not-exist')).to_not be_present
    end

    it "returns false if the element is stale" do
      wd_element = browser.div(id: "foo").wd

      # simulate element going stale during lookup
      allow(browser.driver).to receive(:find_element).with(:id, 'foo') { wd_element }
      browser.refresh

      expect(browser.div(:id, 'foo')).to_not be_present
    end

  end

  describe "#enabled?" do
    before do
      browser.goto(WatirSpec.url_for("forms_with_input_elements.html"))
    end

    it "returns true if the element is enabled" do
      expect(browser.element(name: 'new_user_submit')).to be_enabled
    end

    it "returns false if the element is disabled" do
      expect(browser.element(name: 'new_user_submit_disabled')).to_not be_enabled
    end

    it "raises UnknownObjectException if the element doesn't exist" do
      expect { browser.element(name: "no_such_name").enabled? }.to raise_error(Watir::Exception::UnknownObjectException)
    end
  end

  describe "#reset!" do
    it "successfully relocates collection elements after a reset!" do
      browser.goto(WatirSpec.url_for("wait.html"))
      element = browser.div(:id, 'foo')
      expect(element).to exist
      browser.refresh
      expect(element.exist?).to be false unless Watir.always_locate?
      element.send :reset!
      expect(element).to exist
    end
  end

  describe "#exists?" do
    before do
      browser.goto WatirSpec.url_for('removed_element.html')
    end

    it "does not propagate StaleElementReferenceErrors" do
      button = browser.button(id: "remove-button")
      element = browser.div(id: "text")

      expect(element).to exist
      button.click
      expect(element).to_not exist
    end

    it "returns false when an element from a collection becomes stale" do
      button = browser.button(id: "remove-button")
      text = browser.divs(id: "text").first

      expect(text).to exist
      button.click
      expect(text).to_not exist
    end

    it "returns false when an element becomes stale" do
      wd_element = browser.div(id: "text").wd

      # simulate element going stale during lookup
      allow(browser.driver).to receive(:find_element).with(:id, 'text') { wd_element }
      browser.refresh

      expect(browser.div(:id, 'text')).to_not exist
    end

    it "returns appropriate value when an ancestor element becomes stale" do
      stale_element = browser.div(id: 'top').div(id: 'middle').div(id: 'bottom')
      expect(stale_element.present?).to be true # look up and store @element for each element in hierarchy

      grandparent = stale_element.instance_variable_get('@parent').instance_variable_get('@parent').instance_variable_get('@element')

      # simulate element going stale during lookup
      allow(grandparent).to receive('enabled?') { raise Selenium::WebDriver::Error::ObsoleteElementError }

      browser.refresh
      expect(stale_element.present?).to be Watir.always_locate?
    end
  end

  describe "#element_call" do

    it 'handles exceptions when taking an action on an element that goes stale during execution' do
      browser.goto WatirSpec.url_for('removed_element.html')

      watir_element = browser.div(id: "text")

        # simulate element going stale after assert_exists and before action taken
      allow(watir_element).to receive(:text) do
        watir_element.send :assert_exists
        browser.refresh
        watir_element.send(:element_call) { watir_element.instance_variable_get('@element').text }
      end

      if Watir.always_locate?
        expect { watir_element.text }.to_not raise_error
      else
        expect { watir_element.text }.to raise_error Selenium::WebDriver::Error::StaleElementReferenceError
      end
    end

  end

  describe "#hover" do
    not_compliant_on %i(webdriver firefox synthesized_events),
                     %i(webdriver internet_explorer),
                     %i(webdriver iphone),
                     %i(webdriver safari) do
      it "should hover over the element" do
        browser.goto WatirSpec.url_for('hover.html')
        link = browser.a

        expect(link.style("font-size")).to eq "10px"
        link.hover
        expect(link.style("font-size")).to eq "20px"
      end
    end
  end

  describe ".new" do
    it "finds elements matching the conditions when given a hash of :how => 'what' arguments" do
      expect(browser.checkbox(name: 'new_user_interests', title: 'Dancing is fun!').value).to eq 'dancing'
      expect(browser.text_field(class_name: 'name', index: 1).id).to eq 'new_user_last_name'
    end

    it "raises UnknownObjectException with a sane error message when given a hash of :how => 'what' arguments (non-existing object)" do
      expect { browser.text_field(index: 100, name: "foo").id }.to raise_error(Watir::Exception::UnknownObjectException)
    end

    it "raises ArgumentError if given the wrong number of arguments" do
      container = double("container").as_null_object
      expect { Watir::Element.new(container, 1,2,3,4) }.to raise_error(ArgumentError)
      expect { Watir::Element.new(container, "foo") }.to raise_error(ArgumentError)
    end
  end

  describe "#eq and #eql?" do
    before { browser.goto WatirSpec.url_for("definition_lists.html") }

    it "returns true if the two elements point to the same DOM element" do
      a = browser.dl(id: "experience-list")
      b = browser.dl

      expect(a).to eq b
      expect(a).to eql(b)
    end

    it "returns false if the two elements are not the same" do
      a = browser.dls[0]
      b = browser.dls[1]

      expect(a).to_not eq b
      expect(a).to_not eql(b)
    end

    it "returns false if the other object is not an Element" do
      expect(browser.dl).to_not eq 1
    end
  end

  describe "data-* attributes" do
    before { browser.goto WatirSpec.url_for("data_attributes.html") }

    bug "http://github.com/jarib/celerity/issues#issue/27", :celerity do
      it "finds elements by a data-* attribute" do
        expect(browser.p(data_type: "ruby-library")).to exist
      end

      it "returns the value of a data-* attribute" do
        expect(browser.p.data_type).to eq "ruby-library"
      end
    end
  end

  describe "aria-* attributes" do
    before { browser.goto WatirSpec.url_for("aria_attributes.html") }

    bug "http://github.com/jarib/celerity/issues#issue/27", :celerity do
      it "finds elements by a aria-* attribute" do
        expect(browser.p(aria_label: "ruby-library")).to exist
      end

      it "returns the value of a aria-* attribute" do
        expect(browser.p.aria_label).to eq "ruby-library"
      end
    end
  end

  describe "finding with unknown tag name" do
    it "finds an element by xpath" do
      expect(browser.element(xpath: "//*[@for='new_user_first_name']")).to exist
    end

    it "finds an element by arbitrary attribute" do
      expect(browser.element(title: "no title")).to exist
    end

    it "raises MissingWayOfFindingObjectException if the attribute is invalid for the element type" do
      expect {
        browser.element(for: "no title").exists?
      }.to raise_error(Watir::Exception::MissingWayOfFindingObjectException)

      expect {
        browser.element(value: //).exists?
      }.to raise_error(Watir::Exception::MissingWayOfFindingObjectException)
    end

    it "finds several elements by xpath" do
      expect(browser.elements(xpath: "//a").length).to eq 1
    end

    it "finds finds several elements by arbitrary attribute" do
      expect(browser.elements(id: /^new_user/).length).to eq 32
    end

    it "finds an element from an element's subtree" do
      expect(browser.fieldset.element(id: "first_label")).to exist
      expect(browser.field_set.element(id: "first_label")).to exist
    end

    it "finds several elements from an element's subtree" do
      expect(browser.fieldset.elements(xpath: ".//label").length).to eq 14
    end
  end

  describe "#to_subtype" do
    it "returns a CheckBox instance" do
      e = browser.input(xpath: "//input[@type='checkbox']").to_subtype
      expect(e).to be_kind_of(Watir::CheckBox)
    end

    it "returns a Radio instance" do
      e = browser.input(xpath: "//input[@type='radio']").to_subtype
      expect(e).to be_kind_of(Watir::Radio)
    end

    it "returns a Button instance" do
      es = [
        browser.input(xpath: "//input[@type='button']").to_subtype,
        browser.input(xpath: "//input[@type='submit']").to_subtype,
        browser.input(xpath: "//input[@type='reset']").to_subtype,
        browser.input(xpath: "//input[@type='image']").to_subtype
      ]

      es.all? { |e| expect(e).to be_kind_of(Watir::Button) }
    end

    it "returns a TextField instance" do
      e = browser.input(xpath: "//input[@type='text']").to_subtype
      expect(e).to be_kind_of(Watir::TextField)
    end

    it "returns a FileField instance" do
      e = browser.input(xpath: "//input[@type='file']").to_subtype
      expect(e).to be_kind_of(Watir::FileField)
    end

    it "returns a Div instance" do
      el = browser.element(xpath: "//*[@id='messages']").to_subtype
      expect(el).to be_kind_of(Watir::Div)
    end
  end

  describe "#focus" do
    bug "http://code.google.com/p/selenium/issues/detail?id=157", %i(webdriver firefox) do
      it "fires the onfocus event for the given element" do
        tf = browser.text_field(id: "new_user_occupation")
        expect(tf.value).to eq "Developer"
        tf.focus
        expect(browser.div(id: "onfocus_test").text).to eq "changed by onfocus event"
      end
    end
  end

  describe "#focused?" do
    it "knows if the element is focused" do
      expect(browser.element(id: 'new_user_first_name')).to be_focused
      expect(browser.element(id: 'new_user_last_name')).to_not be_focused
    end
  end

  describe "#fire_event" do
    it "should fire the given event" do
      expect(browser.div(id: "onfocus_test").text).to be_empty
      browser.text_field(id: "new_user_occupation").fire_event('onfocus')
      expect(browser.div(id: "onfocus_test").text).to eq "changed by onfocus event"
    end
  end

  describe "#parent" do
    bug "http://github.com/jarib/celerity/issues#issue/28", :celerity do
      it "gets the parent of this element" do
        expect(browser.text_field(id: "new_user_email").parent).to be_instance_of(Watir::FieldSet)
      end

      it "returns nil if the element has no parent" do
        expect(browser.body.parent.parent).to be_nil
      end
    end
  end

  describe "#visible?" do
    it "returns true if the element is visible" do
      expect(browser.text_field(id: "new_user_email")).to be_visible
    end

    it "raises UnknownObjectException exception if the element does not exist" do
      expect {browser.text_field(id: "no_such_id").visible?}.to raise_error(Watir::Exception::UnknownObjectException)
    end

    it "raises UnknownObjectException exception if the element is stale" do
      wd_element = browser.text_field(id: "new_user_email").wd

      # simulate element going stale during lookup
      allow(browser.driver).to receive(:find_element).with(:id, 'new_user_email') { wd_element }
      browser.refresh

      expect { browser.text_field(id: 'new_user_email').visible? }.to raise_error(Watir::Exception::UnknownObjectException)
    end

    it "returns true if the element has style='visibility: visible' even if parent has style='visibility: hidden'" do
      expect(browser.div(id: "visible_child")).to be_visible
    end

    it "returns false if the element is input element where type eq 'hidden'" do
      expect(browser.hidden(id: "new_user_interests_dolls")).to_not be_visible
    end

    it "returns false if the element has style='display: none;'" do
      expect(browser.div(id: 'changed_language')).to_not be_visible
    end

    it "returns false if the element has style='visibility: hidden;" do
      expect(browser.div(id: 'wants_newsletter')).to_not be_visible
    end

    it "returns false if one of the parent elements is hidden" do
      expect(browser.div(id: 'hidden_parent')).to_not be_visible
    end
  end

  describe "#exist?" do
    context ":class locator" do
      before do
        browser.goto(WatirSpec.url_for("class_locator.html"))
      end

      it "matches when the element has a single class" do
        e = browser.div(class: "a")
        expect(e).to exist
        expect(e.class_name).to eq "a"
      end

      it "matches when the element has several classes" do
        e = browser.div(class: "b")
        expect(e).to exist
        expect(e.class_name).to eq "a b"
      end

      it "does not match only part of the class name" do
        expect(browser.div(class: "c")).to_not exist
      end

      it "matches part of the class name when given a regexp" do
        expect(browser.div(class: /c/)).to exist
      end
    end

    it "doesn't raise when called on nested elements" do
      expect(browser.div(id: 'no_such_div').link(id: 'no_such_id')).to_not exist
    end

    it "raises if both :xpath and :css are given" do
      expect { browser.div(xpath: "//div", css: "div").exists? }.to raise_error(ArgumentError)
    end

    it "doesn't raise when selector has with :xpath has :index" do
      expect(browser.div(xpath: "//div", index: 1)).to exist
    end

    it "raises ArgumentError error if selector hash with :xpath has multiple entries" do
      expect { browser.div(xpath: "//div", class: "foo").exists? }.to raise_error(ArgumentError)
    end

    it "doesn't raise when selector has with :css has :index" do
      expect(browser.div(css: "div", index: 1)).to exist
    end

    it "raises ArgumentError error if selector hash with :css has multiple entries" do
      expect { browser.div(css: "div", class: "foo").exists? }.to raise_error(ArgumentError)
    end
  end

  describe '#send_keys' do
    before(:each) do
      phantom = browser.driver.capabilities.browser_name == 'phantomjs'
      @c = RUBY_PLATFORM =~ /darwin/ && !phantom ? :command : :control
      browser.goto(WatirSpec.url_for('keylogger.html'))
    end

    let(:receiver) { browser.text_field(id: 'receiver') }
    let(:events)   { browser.element(id: 'output').ps.size }

    it 'sends keystrokes to the element' do
      receiver.send_keys 'hello world'
      expect(receiver.value).to eq 'hello world'
      expect(events).to eq 11
    end

    it 'accepts arbitrary list of arguments' do
      receiver.send_keys 'hello', 'world'
      expect(receiver.value).to eq 'helloworld'
      expect(events).to eq 10
    end

    # key combinations probably not ever possible on mobile devices?
    bug "http://code.google.com/p/chromium/issues/detail?id=93879", %i(webdriver chrome), %i(webdriver iphone) do
      not_compliant_on %i(webdriver safari) do
        it 'performs key combinations' do
          receiver.send_keys 'foo'
          receiver.send_keys [@c, 'a']
          receiver.send_keys :backspace
          expect(receiver.value).to be_empty
          expect(events).to eq 6
        end

        it 'performs arbitrary list of key combinations' do
          receiver.send_keys 'foo'
          receiver.send_keys [@c, 'a'], [@c, 'x']
          expect(receiver.value).to be_empty
          expect(events).to eq 7
        end

        it 'supports combination of strings and arrays' do
          receiver.send_keys 'foo', [@c, 'a'], :backspace
          expect(receiver.value).to be_empty
          expect(events).to eq 6
        end
      end
    end
  end

  describe "#flash" do

    let(:h2) { browser.h2(text: 'Add user') }

    it 'returns the element on which it was called' do
      expect(h2.flash).to eq h2
    end
  end

  describe '#inner_html' do
    it 'returns inner HTML code of element' do
      browser.goto WatirSpec.url_for('inner_outer.html')
      div = browser.div(id: 'foo')
      expect(div.inner_html).to eq('<a href="#">hello</a>')
    end
  end

  describe '#outer_html' do
    it 'returns outer (inner + element itself) HTML code of element' do
      browser.goto WatirSpec.url_for('inner_outer.html')
      div = browser.div(id: 'foo')
      expect(div.outer_html).to eq('<div id="foo"><a href="#">hello</a></div>')
    end
  end
end
