module Watir

  class ElementPreconditions

    PRESENT_EXPECTED = %i[set clear set? click double_click right_click
hover drag_and_drop_on drag_and_drop_by send_keys enabled submit selected?
include? select_by_string select_by_regexp]

    def self.load_static(listener)
      listener.add(:set) do |element, *|
        element.clear if element.is_a?(TextField) || element.is_a?(TextArea)
      end
      listener.add(:clear) do |element, *|
        element.send(:assert_writable) if element.is_a?(TextField) || element.is_a?(TextArea)
      end
      listener.add(:send_keys) { |element, *| element.send :assert_writable }
      listener.add(:click) { |element, *| element.send :assert_enabled }
      listener.add(:double_click) { |element, caller| element.send :assert_has_input_devices_for, caller }
      listener.add(:right_click) { |element, caller| element.send :assert_has_input_devices_for, caller }
      listener.add(:hover) { |element, caller| element.send :assert_has_input_devices_for, caller }
      listener.add(:drag_and_drop_on) { |element, caller| element.send :assert_has_input_devices_for, caller }
      listener.add(:drag_and_drop_by) { |element, caller| element.send :assert_has_input_devices_for, caller }
      new(listener)
    end

    def self.load_dynamic(listener)
      @waits = true
      load_static(listener)
    end

    def initialize(listener)
      @listener = listener
    end

    def waits?
      !!@waits
    end

    def execute(element)
      caller = element.send(:caller_locations)[1].label.to_sym
      actions_array = @listener.find(caller)
      if actions_array.empty? && waits? && PRESENT_EXPECTED.include?(caller)
        element.send :wait_for_present
      elsif actions_array.empty? && waits?
        element.send :wait_for_exists
      elsif actions_array.empty?
        element.send :assert_exists
      end
      actions_array.each do |proc|
        proc.call(element, caller)
      end
    end

  end # ElementPreconditions
end # Watir
