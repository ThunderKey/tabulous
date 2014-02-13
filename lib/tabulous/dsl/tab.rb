require 'ostruct'

module Tabulous
  module Dsl
    class Tab
      attr_reader :tab

      def initialize(name)
        @tab = ::Tabulous::Tab.new
        @tab.name = name
      end

      def create(data, config)
        require_key :text, data
        require_key :link_path, data
        require_key :visible_when, data
        require_key :enabled_when, data
        require_key :active_when, data
        @tab.text = data[:text]
        @tab.link_path = data[:link_path]
        @tab.http_verb = data[:http_verb] if data[:http_verb]
        @tab.visible_when = data[:visible_when]
        @tab.enabled_when = data[:enabled_when]
        if data[:tabs]
          subtabs = data[:tabs]
          subtabs_config = subtabs[:config] || {}
          @tab.tabs = ::Tabulous::Dsl::Tabs.new(subtabs_config, config).create(subtabs)
        end
        instance_exec(&data[:active_when])
        @tab
      end

      def process(parent_tab, &block)
        @tab.name = name.to_s
        if parent_tab
          @tab.kind = :subtab
          @tab.parent = parent_tab
        end
        @called = []
        instance_exec(&block)
        check_for_errors!
        @tab
      end

      def text(val = nil, &block)
        @called << :text
        @tab.text = block_given? ? block : val
      end

      def link_path(val = nil, &block)
        @called << :link_path
        @tab.link_path = block_given? ? block : val
      end

      def http_verb(val = nil, &block)
        @called << :http_verb
        @tab.http_verb = block_given? ? block : val
      end

      def visible_when(val = nil, &block)
        @called << :visible_when
        @tab.visible_when = block_given? ? block : val
      end

      def enabled_when(val = nil, &block)
        @called << :enabled_when
        @tab.enabled_when = block_given? ? block : val
      end

      def active_when(&block)
        @called << :active_when
        instance_exec(&block)
      end

      def a_subtab_is_active
        @tab.declared_to_have_subtabs = true
      end

      def in_actions(*actions)
        @active_mediator = OpenStruct.new
        @active_mediator.this = self
        @active_mediator.actions = actions
        def @active_mediator.of_controller(controller)
          self.controller = controller
          self.this.send(:register_rule)
        end
        @active_mediator
      end

      def in_action(action)
        in_actions(action)
      end

      def method_missing(method, *args, &block)
        raise UnknownDeclarationError, "Unknown declaration '#{method}'."
      end

    private

      def check_for_errors!
        [:text, :link_path, :visible_when, :enabled_when, :active_when].each do |advice|
          if !@called.include?(advice)
            raise MissingDeclarationError, "Missing '#{advice}' in tab #{@tab.name}."
          end
        end
      end

      def register_rule
        @tab.add_active_actions(@active_mediator.controller, @active_mediator.actions)
      end

      def require_key key, data
        if !data.key?(key) || !data[key]
          raise "The key #{key} is required for the tab #{@tab.name}"
        end
      end

    end
  end
end
