module Liability
  class RepaymentSummary
    attr_reader :account

    def initialize(account)
      @account = account
    end

    def original_amount_money
      @original_amount_money ||= Money.new(original_amount_value, account.currency)
    end

    def paid_money
      total = payments_total
      if total.positive?
        Money.new(total, account.currency)
      else
        paid = original_amount_money.amount.to_d - remaining_from_balance.amount.to_d
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
      @payment_entries ||= account.entries
        .joins("INNER JOIN transactions ON transactions.id = entries.entryable_id AND entries.entryable_type = 'Transaction'")
        .where("entries.amount < 0")
        .order(date: :desc, created_at: :desc)
        .to_a
    end

    def paid_off?
      account.disabled? || remaining_money.amount.to_d <= 0
    end

    private

      def payments_total
        payment_entries.sum { |entry| entry.amount.abs.to_d }
      end

      def original_amount_value
        candidates = []

        opening = account.opening_anchor_balance
        candidates << opening.to_d if opening.present? && opening.to_d.positive?

        peak = account.balances.maximum(:balance)
        candidates << peak.to_d if peak.present? && peak.to_d.positive?

        paid = payments_total
        current = account.balance.to_d
        candidates << (current + paid) if (current + paid).positive?

        first_valuation = account.first_valuation&.amount
        candidates << first_valuation.to_d if first_valuation.present? && first_valuation.to_d.positive?

        candidates.max || current
      end

      def remaining_from_balance
        account.balance_money
      end
  end
end
