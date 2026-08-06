module Dashboard
  class Overview
    EXCLUDED_ASSET_TYPES = %w[Investment Crypto].freeze

    attr_reader :family

    def initialize(family)
      @family = family
    end

    def cash_accounts
      @cash_accounts ||= family.accounts.visible
        .where(accountable_type: "Depository")
        .with_attached_logo
        .alphabetically
    end

    def cash_total_money
      Money.new(cash_accounts.sum(&:balance), family.currency)
    end

    def cash_series(period:)
      if cash_accounts.empty?
        return Series.new(start_date: Date.current, end_date: Date.current, interval: "1 day", values: [])
      end

      Balance::ChartSeriesBuilder.new(
        account_ids: cash_accounts.pluck(:id),
        currency: family.currency,
        period: period,
        favorable_direction: "up"
      ).balance_series
    end

    def dashboard_asset_accounts
      family.accounts.visible.assets
        .where.not(accountable_type: EXCLUDED_ASSET_TYPES)
        .with_attached_logo
        .alphabetically
    end

    def liability_accounts
      @liability_accounts ||= active_liability_records.select do |account|
        repayment_summary_for(account).remaining_money.amount.to_d.positive?
      end
    end

    def paid_off_liability_accounts
      @paid_off_liability_accounts ||= family.accounts.where(status: "disabled").liabilities
        .includes(:accountable)
        .order(updated_at: :desc)
    end

    def repayment_summary_for(account)
      @repayment_summaries ||= {}
      @repayment_summaries[account.id] ||= Liability::RepaymentSummary.new(account)
    end

    def liabilities_total_money
      Money.new(
        liability_accounts.sum { |account| repayment_summary_for(account).remaining_money.amount.to_d },
        family.currency
      )
    end

    def last_payment_for(account)
      repayment_summary_for(account).payment_entries.first
    end

    private

      def active_liability_records
        @active_liability_records ||= family.accounts.visible.liabilities
          .includes(:accountable, :balances)
          .with_attached_logo
          .alphabetically
      end
  end
end
