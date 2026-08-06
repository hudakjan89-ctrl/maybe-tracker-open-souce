module Liability
  class RepaymentSummary
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def original_amount_money
      @original_amount_money ||= begin
        opening = account.opening_anchor_balance
        if opening.present? && opening.to_d.positive?
          Money.new(opening, account.currency)
        else
          peak = account.balances.maximum(:balance)
          if peak.present? && peak.to_d.positive?
            Money.new(peak, account.currency)
          else
            account.first_valuation_amount
          end
        end
      end
    end

    def remaining_money
      account.balance_money
    end

    def paid_money
      paid = original_amount_money - remaining_money
      paid.amount.negative? ? Money.new(0, account.currency) : paid
    end

    def progress_percent
      original = original_amount_money.amount.to_d
      return 100 if original <= 0 || remaining_money.amount.to_d <= 0

      ((paid_money.amount.to_d / original) * 100).round.clamp(0, 100)
    end

    def payment_entries
      account.entries
        .joins("INNER JOIN transactions ON transactions.id = entries.entryable_id AND entries.entryable_type = 'Transaction'")
        .where("entries.amount < 0")
        .order(date: :desc, created_at: :desc)
    end

    def paid_off?
      account.disabled? || remaining_money.amount.to_d <= 0
    end
  end
end
