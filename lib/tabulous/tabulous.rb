module Tabulous
  class << self
    def setup(&block)
      Dsl::Setup.process(&block)
    end

    def create config
      Dsl::Setup.create config
    end
  end
end
