# encoding: utf-8
module Watir
  class IFrame < HTMLElement

    def initialize(*args)
      super(*args)
      @browsing_context = BrowsingContext.new(self)
    end

    def locate
      @selector.merge!(:tag_name => frame_tag)
      super
    end

      locator = locator_class.new(@parent.wd, @selector.merge(:tag_name => frame_tag), self.class.attribute_list)
      element = locator.locate
      element or raise UnknownFrameException, "unable to locate #{@selector[:tag_name]} using #{selector_string}"

      FramedDriver.new(element, driver)
    end

    def switch_to
      @browsing_context.switch_to
    end

    def assert_exists
      if @selector.key? :element
        raise UnknownFrameException, "wrapping a WebDriver element as a Frame is not currently supported"
      end

      super
    end

    def html
      assert_exists

      # this will actually give us the innerHTML instead of the outerHTML of the <frame>,
      # but given the choice this seems more useful
      element_call { execute_atom(:getOuterHtml, @element.find_element(tag_name: "html")).strip }
    end

    def execute_script(*args)
      browser.execute_script(*args)
    end

    private

    def frame_tag
      'iframe'
    end

  end # IFrame


  class IFrameCollection < ElementCollection

    def to_a
      # In case `#all_elements` returns empty array, but `#elements`
      # returns non-empty array (i.e. any frame has loaded between these two calls),
      # index will return nil. That's why `#all_elements` should always
      # be called after `#elements.`
      element_indexes = elements.map { |el| all_elements.index(el) }
      element_indexes.map { |idx| element_class.new(@parent, tag_name: @selector[:tag_name], index: idx) }
    end

    def element_class
      IFrame
    end

    private

    def all_elements
      locator_class.new(
        @parent.wd,
        { tag_name: @selector[:tag_name] },
        element_class.attribute_list
      ).locate_all
    end

  end # IFrameCollection


  class Frame < IFrame

    private

    def frame_tag
      'frame'
    end

  end # Frame


  class FrameCollection < IFrameCollection

    def element_class
      Frame
    end

  end # FrameCollection


  module Container

    def frame(*args)
      Frame.new(self, extract_selector(args).merge(tag_name: "frame"))
    end

    def frames(*args)
      FrameCollection.new(self, extract_selector(args).merge(tag_name: "frame"))
    end

  end # Container
end # Watir
