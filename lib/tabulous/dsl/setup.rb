module Tabulous
  module Dsl
    class Setup
      class << self

        def process(&block)
          instance_exec(OldVersionChecker.new, &block)
        end

        def create(config)
          default_config = config.delete(:default_config) || {}
          config.each do |tabset_name, tabset_data|
            raise ':tabs is needed to create a new setup' unless tabset_data[:tabs]
            Tabsets.add(tabset_name, Dsl::Tabs.new(tabset_data[:config], default_config).create(tabset_data[:tabs]))
          end
        end

        def customize(&block)
          Dsl::Config.process(&block)
        end

        def use_css_scaffolding(&block)
          ::Tabulous::Config.use_css_scaffolding = true
          Dsl::Config.process(&block) if block_given?
        end

        def tabs(tabset_name = :default, config = {}, &block)
          tabset = Dsl::Tabs.new(config).process(&block)
          Tabsets.add(tabset_name, tabset)
        end

        def method_missing(method, *args, &block)
          raise UnknownDeclarationError, "Unknown declaration '#{method}'. Valid declarations here are tabs, customize, and use_css_scaffolding."
        end

      end
    end
  end
end
