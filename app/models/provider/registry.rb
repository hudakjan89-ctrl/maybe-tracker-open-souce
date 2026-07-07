class Provider::Registry
  Error = Class.new(StandardError)

  class << self
    def get_provider(_name)
      nil
    end
  end
end
