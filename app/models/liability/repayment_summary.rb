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
            amount = account.first_valuation_amount
            amount.amount.positive? ? amount : account.balance_money
          end
        end
      end
    end

    def paid_money
      payment_total = payment_entries.sum { |entry| entry.amount.abs.to_d }
      if payment_total.positive?
        Money.new(payment_total, account.currency)
      else
        paid = original_amount_money.amount.to_d - remaining_from_balance.to_d
        Money.new([ paid, 0 ].max, account.currency)
      end
    end

    def remaining_money
      remaining = original_amount_money.amount.to_d - paid_money.amount.to_d
      Money.new([ remaining, 0 ].max, account.currency)
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

    private

      def remaining_from_balance
        account.balance_money
      end
  end
end
