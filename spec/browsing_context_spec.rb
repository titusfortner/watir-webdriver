require File.expand_path('watirspec/spec_helper', File.dirname(__FILE__))

describe Watir::BrowsingContext do

  before { browser.goto(WatirSpec.url_for("nested_iframes.html", :needs_server => true)) }
  after { browser.driver.switch_to.default_content }

  describe ".new" do
    it "takes a Browser instance as argument" do
      expect { Watir::BrowsingContext.new(browser) }.to_not raise_error
    end

    it "takes an IFrame instance as argument" do
      expect { Watir::BrowsingContext.new(browser.frame) }.to_not raise_error
    end

    it "raises ArgumentError for invalid args" do
      expect { Watir::BrowsingContext.new(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe "#switch_to" do
    it "does not error when already in default context" do
      expect(browser.browsing_context.top_level?).to be true
      expect { browser.switch_to }.to_not raise_error
    end

    it "properly switches to default child frame" do
      expect(browser.browsing_context.top_level?).to be true
      expect(browser.browsing_context.in_context?).to be true

      iframe = browser.iframe(:id, 'one')
      expect(iframe.browsing_context.in_context?).to be false

      expect { iframe.switch_to }.to_not raise_error
      expect(iframe.browsing_context.in_context?).to be false
      expect(iframe.browsing_context.top_level?).to be false

    end

  end

end
