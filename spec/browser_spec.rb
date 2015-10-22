require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Watir::Browser do

  describe ".new" do
    it "passes the args to selenium" do
      expect(Selenium::WebDriver).to receive(:for).with(:firefox, :foo).and_return(nil)
      Watir::Browser.new(:firefox, :foo)
    end

    it "takes a Driver instance as argument" do
      mock_driver = double(Selenium::WebDriver::Driver)
      expect(Selenium::WebDriver::Driver).to receive(:===).with(mock_driver).and_return(true)
      expect { Watir::Browser.new(mock_driver) }.to_not raise_error
    end

    it "raises ArgumentError for invalid args" do
      expect { Watir::Browser.new(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe "#execute_script" do
    before { browser.goto WatirSpec.url_for("definition_lists.html") }

    it "wraps elements as Watir objects" do
      returned = browser.execute_script("return document.body")
      expect(returned).to be_kind_of(Watir::Body)
    end

    it "wraps elements in an array" do
      list = browser.execute_script("return [document.body];")
      expect(list.size).to eq 1
      expect(list.first).to be_kind_of(Watir::Body)
    end

    it "wraps elements in a Hash" do
      hash = browser.execute_script("return {element: document.body};")
      expect(hash['element']).to be_kind_of(Watir::Body)
    end

    it "wraps elements in a deep object" do
      hash = browser.execute_script("return {elements: [document.body], body: {element: document.body }}")

      expect(hash['elements'].first).to be_kind_of(Watir::Body)
      expect(hash['body']['element']).to be_kind_of(Watir::Body)
    end
  end

  describe "#send_key{,s}" do
    it "sends keystrokes to the active element" do
      browser.goto WatirSpec.url_for "forms_with_input_elements.html"

      browser.send_keys "hello"
      expect(browser.text_field(id: "new_user_first_name").value).to eq "hello"
    end

    it "sends keys to a frame" do
      browser.goto WatirSpec.url_for "frames.html"
      tf = browser.frame.text_field(id: "senderElement")
      tf.clear

      browser.frame.send_keys "hello"

      expect(tf.value).to eq "hello"
    end
  end

  it "raises an error when trying to interact with a closed browser" do
    b = WatirSpec.new_browser
    b.goto WatirSpec.url_for "definition_lists.html"
    b.close

    expect { b.dl(id: "experience-list").id }.to raise_error(Watir::Exception::Error, "browser was closed")
  end

  describe "#wait_while" do
    it "delegates to the Wait module" do
      expect(Watir::Wait).to receive(:while).with(3, "foo").and_yield

      called = false
      browser.wait_while(3, "foo") { called = true }

      expect(called).to be true
    end
  end

  describe "#wait_until" do
    it "delegates to the Wait module" do
      expect(Watir::Wait).to receive(:until).with(3, "foo").and_yield

      called = false
      browser.wait_until(3, "foo") { called = true }

      expect(called).to be true
    end
  end

  describe "#wait" do
    it "waits until document.readyState == 'complete'" do
      expect(browser).to receive(:ready_state).and_return('incomplete')
      expect(browser).to receive(:ready_state).and_return('complete')

      browser.wait
    end
  end

  describe "#ready_state" do
    it "gets the document's readyState property" do
      expect(browser).to receive(:execute_script).with('return document.readyState')
      browser.ready_state
    end
  end

  describe "#inspect" do
    it "works even if browser is closed" do
      expect(browser).to receive(:url).and_raise(Errno::ECONNREFUSED)
      expect { browser.inspect }.to_not raise_error
    end
  end

  describe '#screenshot' do
    it 'returns an instance of of Watir::Screenshot' do
      expect(browser.screenshot).to be_kind_of(Watir::Screenshot)
    end
  end

  describe "#exists?" do
    after do
      browser.window(index: 0).use
      browser.windows[1..-1].each(&:close)
    end

    it "returns true if we are at a page" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      expect(browser).to exist
    end

    it "returns false if window is closed" do
      browser.goto WatirSpec.url_for("window_switching.html")
      browser.a(id: "open").click
      browser.window(title: "closeable window").use
      browser.a(id: "close").click
      expect(browser.exists?).to be false
    end

    not_compliant_on(:safariwatir) do
      it "returns false after Browser#close" do
        b = WatirSpec.new_browser
        b.close
        expect(b).to_not exist
      end
    end
  end

  # this should be rewritten - the actual string returned varies a lot between implementations
  describe "#html" do
    it "returns the DOM of the page as an HTML string" do
      browser.goto(WatirSpec.url_for("right_click.html"))
      html = browser.html.downcase # varies between browsers

      expect(html).to match(/^<html/)
      expect(html).to include('<meta ')
      expect(html).to include(' content="text/html; charset=utf-8"')

      not_compliant_on :internet_explorer do
        expect(html).to include(' http-equiv="content-type"')
      end

      deviates_on :internet_explorer9, :internet_explorer10 do
        expect(html).to include(' http-equiv="content-type"')
      end

      not_compliant_on :internet_explorer9, :internet_explorer10 do
        deviates_on :internet_explorer do
          expect(html).to include(' http-equiv=content-type')
        end
      end
    end
  end

  describe "#title" do
    it "returns the current page title" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      expect(browser.title).to eq "Non-control elements"
    end
  end

  describe "#status" do
    # for Firefox, this needs to be enabled in
    # Preferences -> Content -> Advanced -> Change status bar text
    #
    # for IE9, this needs to be enabled in
    # View => Toolbars -> Status bar
    not_compliant_on :firefox, :internet_explorer9, :internet_explorer10 do
      it "returns the current value of window.status" do
        browser.goto(WatirSpec.url_for("non_control_elements.html"))

        browser.execute_script "window.status = 'All done!';"
        expect(browser.status).to eq "All done!"
      end
    end
  end

  describe "#name" do
    it "returns browser name" do
      not_compliant_on :phantomjs do
        expect(browser.name).to eq WatirSpec.implementation.browser_args[0]
      end

      deviates_on :phantomjs do
        expect(browser.name).to be_an_instance_of(Symbol)
      end
    end
  end

  describe "#text" do
    it "returns the text of the page" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      expect(browser.text).to include("Dubito, ergo cogito, ergo sum.")
    end

    it "returns the text also if the content-type is text/plain" do
      # more specs for text/plain? what happens if we call other methods?
      browser.goto(WatirSpec.url_for("plain_text", needs_server: true))
      expect(browser.text.strip).to eq 'This is text/plain'
    end

    it "returns text of top most browsing context" do
      browser.goto(WatirSpec.url_for("nested_iframes.html"))
      browser.iframe(id: 'two').h3.exists?
      expect(browser.text).to eq 'Top Layer'
    end
  end

  describe "#url" do
    it "returns the current url" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      expect(browser.url).to eq WatirSpec.url_for("non_control_elements.html")
    end

    it "always returns top url" do
      browser.goto(WatirSpec.url_for("frames.html"))
      browser.frame.body.exists? # switches to frame
      expect(browser.url).to eq WatirSpec.url_for("frames.html")
    end
  end

  describe "#title" do
    it "returns the current title" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      expect(browser.title).to eq "Non-control elements"
    end

    it "always returns top title" do
      browser.goto(WatirSpec.url_for("frames.html"))
      browser.element(tag_name: 'title').text
      browser.frame.body.exists? # switches to frame
      expect(browser.title).to eq "Frames"
    end
  end

  describe ".start" do
    it "goes to the given URL and return an instance of itself" do
      driver, args = WatirSpec.implementation.browser_args
      browser = Watir::Browser.start(WatirSpec.url_for("non_control_elements.html"), driver, args)

      expect(browser).to be_instance_of(Watir::Browser)
      expect(browser.title).to eq "Non-control elements"
      browser.close
    end
  end

  describe "#goto" do
    not_compliant_on :internet_explorer do
      it "adds http:// to URLs with no URL scheme specified" do
        url = WatirSpec.host[%r{http://(.*)}, 1]
        expect(url).to_not be_nil
        browser.goto(url)
        expect(browser.url).to match(%r[http://#{url}/?])
      end
    end

    it "goes to the given url without raising errors" do
      expect { browser.goto(WatirSpec.url_for("non_control_elements.html")) }.to_not raise_error
    end

    it "goes to the url 'about:blank' without raising errors" do
      expect { browser.goto("about:blank") }.to_not raise_error
    end

    not_compliant_on :internet_explorer, :safari do
      it "goes to a data URL scheme address without raising errors" do
        expect { browser.goto("data:text/html;content-type=utf-8,foobar") }.to_not raise_error
      end
    end

    compliant_on :firefox do
      it "goes to internal Firefox URL 'about:mozilla' without raising errors" do
        expect { browser.goto("about:mozilla") }.to_not raise_error
      end
    end

    compliant_on :opera do
      it "goes to internal Opera URL 'opera:config' without raising errors" do
        expect { browser.goto("opera:config") }.to_not raise_error
      end
    end

    compliant_on :chrome do
      it "goes to internal Chrome URL 'chrome://settings/browser' without raising errors" do
        expect { browser.goto("chrome://settings/browser") }.to_not raise_error
      end
    end

    it "updates the page when location is changed with setTimeout + window.location" do
      browser.goto(WatirSpec.url_for("timeout_window_location.html"))
      Watir::Wait.while {browser.url.include? 'timeout_window_location.html'}
      expect(browser.url).to include("non_control_elements.html")
    end
  end

  describe "#refresh" do
    it "refreshes the page" do
      browser.goto(WatirSpec.url_for("non_control_elements.html"))
      browser.span(class: 'footer').click
      expect(browser.span(class: 'footer').text).to include('Javascript')
      browser.refresh
      expect(browser.span(class: 'footer').text).to_not include('Javascript')
    end
  end

  describe "#execute_script" do
    before { browser.goto(WatirSpec.url_for("non_control_elements.html")) }

    it "executes the given JavaScript on the current page" do
      expect(browser.pre(id: 'rspec').text).to_not eq "javascript text"
      browser.execute_script("document.getElementById('rspec').innerHTML = 'javascript text'")
      expect(browser.pre(id: 'rspec').text).to eq "javascript text"
    end

    it "executes the given JavaScript in the context of an anonymous function" do
      expect(browser.execute_script("1 + 1")).to be_nil
      expect(browser.execute_script("return 1 + 1")).to eq 2
    end

    it "returns correct Ruby objects" do
      expect(browser.execute_script("return {a: 1, \"b\": 2}")).to eq Hash["a" => 1, "b" => 2]
      expect(browser.execute_script("return [1, 2, \"3\"]")).to match_array([1, 2, "3"])
      expect(browser.execute_script("return 1.2 + 1.3")).to eq 2.5
      expect(browser.execute_script("return 2 + 2")).to eq 4
      expect(browser.execute_script("return \"hello\"")).to eq "hello"
      expect(browser.execute_script("return")).to be_nil
      expect(browser.execute_script("return null")).to be_nil
      expect(browser.execute_script("return undefined")).to be_nil
      expect(browser.execute_script("return true")).to be true
      expect(browser.execute_script("return false")).to be false
    end

    it "works correctly with multi-line strings and special characters" do
      expect(browser.execute_script("//multiline rocks!
                            var a = 22; // comment on same line
                            /* more
                            comments */
                            var b = '33';
                            var c = \"44\";
                            return a + b + c")).to eq "223344"
    end
  end

  not_compliant_on :safari do
    describe "#back and #forward" do
      it "goes to the previous page" do
        browser.goto WatirSpec.url_for("non_control_elements.html")
        orig_url = browser.url
        browser.goto WatirSpec.url_for("tables.html")
        new_url = browser.url
        expect(orig_url).to_not eq new_url
        browser.back
        expect(orig_url).to eq browser.url
      end

      it "goes to the next page" do
        urls = []
        browser.goto WatirSpec.url_for("non_control_elements.html")
        urls << browser.url
        browser.goto WatirSpec.url_for("tables.html")
        urls << browser.url

        browser.back
        expect(browser.url).to eq urls.first
        browser.forward
        expect(browser.url).to eq urls.last
      end

      it "navigates between several history items" do
        urls = [ "non_control_elements.html",
                 "tables.html",
                 "forms_with_input_elements.html",
                 "definition_lists.html"
        ].map do |page|
          browser.goto WatirSpec.url_for(page)
          browser.url
        end

        3.times { browser.back }
        expect(browser.url).to eq urls.first
        2.times { browser.forward }
        expect(browser.url).to eq urls[2]
      end
    end
  end

  it "raises UnknownObjectException when trying to access DOM elements on plain/text-page" do
    browser.goto(WatirSpec.url_for("plain_text"))
    expect { browser.div(id: 'foo').id }.to raise_error(Watir::Exception::UnknownObjectException)
  end

end
