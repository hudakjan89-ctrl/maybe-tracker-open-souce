module Demo
  class SampleTransactions
    def initialize(family)
      @family = family
    end

    def generate!
      Demo::Setup.new(@family).populate!(add_transactions: true)
    end
  end
end
