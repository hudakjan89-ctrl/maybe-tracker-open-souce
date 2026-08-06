module Liability
  class PaidOff
    def initialize(account)
      @account = account
    end

    def mark!
      return false if @account.disabled?

      @account.set_current_balance(0) if @account.balance.to_d.positive?
      @account.disable!
      true
    end

    def self.mark!(account)
      new(account).mark!
    end
  end
end
