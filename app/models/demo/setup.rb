module Demo
  class Setup
    CURRENCY = "EUR"

    CATEGORIES = [
      [ "Plat", "#e99537", "circle-dollar-sign", "income" ],
      [ "Príjem", "#4da568", "circle-dollar-sign", "income" ],
      [ "Potraviny", "#eb5429", "utensils", "expense" ],
      [ "Reštaurácie", "#df4e92", "utensils", "expense" ],
      [ "Nákupy", "#e99537", "shopping-cart", "expense" ],
      [ "Doprava", "#6471eb", "bus", "expense" ],
      [ "Zábava", "#df4e92", "drama", "expense" ],
      [ "Bývanie", "#6471eb", "house", "expense" ],
      [ "Zdravie", "#4da568", "pill", "expense" ],
      [ "Predplatné", "#805dee", "credit-card", "expense" ]
    ].freeze

    EXPENSE_TEMPLATES = [
      { name: "Tesco", category: "Potraviny", amount: 35..95 },
      { name: "Kaufland", category: "Potraviny", amount: 25..80 },
      { name: "Lidl", category: "Potraviny", amount: 15..55 },
      { name: "Bolt", category: "Doprava", amount: 4..18 },
      { name: "Benzín", category: "Doprava", amount: 40..75 },
      { name: "Netflix", category: "Predplatné", amount: 12..12 },
      { name: "Spotify", category: "Predplatné", amount: 6..6 },
      { name: "Vodafone", category: "Predplatné", amount: 20..25 },
      { name: "Starbucks", category: "Reštaurácie", amount: 3..8 },
      { name: "IKEA", category: "Nákupy", amount: 30..150 },
      { name: "DM drogéria", category: "Nákupy", amount: 8..35 },
      { name: "Kino", category: "Zábava", amount: 10..25 },
      { name: "Lekáreň", category: "Zdravie", amount: 5..40 }
    ].freeze

    SECURITIES = [
      { ticker: "VWCE", name: "Vanguard FTSE All-World UCITS ETF", price: 118 },
      { ticker: "SXR8", name: "iShares Core S&P 500 UCITS ETF", price: 520 },
      { ticker: "EUNL", name: "iShares Core MSCI World UCITS ETF", price: 95 }
    ].freeze

    def initialize(family)
      @family = family
      @rng = Random.new(42)
    end

    # Idempotent setup — safe to call multiple times.
    def populate!(add_transactions: false)
      configure_family!

      synced_account_ids = []

      ActiveRecord::Base.transaction do
        ensure_categories!
        checking = ensure_account!(Depository, "Hlavný účet", subtype: "checking")
        savings = ensure_account!(Depository, "Sporenie", subtype: "savings")
        credit = ensure_account!(CreditCard, "Kreditná karta")
        investment = ensure_account!(Investment, "Investičné portfólio", subtype: "brokerage")

        synced_account_ids = [ checking, savings, credit, investment ].map(&:id)

        if add_transactions || checking.transactions.count < 5
          create_monthly_income!(checking)
          create_recurring_expenses!(checking, savings, credit)
          create_random_expenses!(checking)
        end

        create_investments!(investment) if investment.entries.trades.none?
        create_liabilities!(checking)
        ensure_budget!

        synced_account_ids = @family.accounts.pluck(:id)
      end

      sync_accounts!(synced_account_ids)
    end

    private

      def configure_family!
        @family.update!(
          currency: CURRENCY,
          locale: "sk",
          date_format: "%d.%m.%Y",
          country: "SK"
        )
      end

      def ensure_categories!
        CATEGORIES.each do |name, color, icon, classification|
          category = @family.categories.find_or_initialize_by(name: name)
          category.color = color
          category.lucide_icon = icon
          category.classification = classification
          category.save!
        end
      end

      def category(name)
        @family.categories.find_by!(name: name)
      end

      def ensure_account!(accountable_class, name, subtype: nil)
        existing = @family.accounts.find_by(name: name)
        return existing if existing

        accountable = accountable_class.new
        accountable.subtype = subtype if subtype && accountable.respond_to?(:subtype=)

        @family.accounts.create!(
          accountable: accountable,
          name: name,
          balance: 0,
          cash_balance: 0,
          currency: CURRENCY
        )
      end

      def create_monthly_income!(account)
        6.downto(0) do |months_ago|
          date = months_ago.months.ago.to_date.beginning_of_month + 1.day
          next if date > Date.current

          account.entries.create!(
            entryable: Transaction.new(category: category("Plat")),
            amount: -@rng.rand(2_200..3_200),
            name: "Výplata",
            currency: CURRENCY,
            date: date
          )
        end
      end

      def create_recurring_expenses!(checking, savings, credit)
        6.downto(0) do |months_ago|
          month = months_ago.months.ago.to_date.beginning_of_month

          checking.entries.create!(
            entryable: Transaction.new(category: category("Bývanie")),
            amount: @rng.rand(450..650),
            name: "Nájom",
            currency: CURRENCY,
            date: month + 2.days
          )

          savings.entries.create!(
            entryable: Transaction.new(category: category("Príjem")),
            amount: -@rng.rand(100..300),
            name: "Úrok zo sporenia",
            currency: CURRENCY,
            date: month + 5.days
          )

          credit.entries.create!(
            entryable: Transaction.new(category: category("Nákupy")),
            amount: @rng.rand(80..250),
            name: "Online nákupy",
            currency: CURRENCY,
            date: month + 10.days
          )
        end
      end

      def create_random_expenses!(account)
        50.times do
          template = EXPENSE_TEMPLATES[@rng.rand(EXPENSE_TEMPLATES.length)]
          date = @rng.rand(6.months.ago.to_date..Date.current)

          account.entries.create!(
            entryable: Transaction.new(category: category(template[:category])),
            amount: @rng.rand(template[:amount]),
            name: template[:name],
            currency: CURRENCY,
            date: date
          )
        end
      end

      def create_liabilities!(checking)
        mortgage = ensure_loan!("Hypotéka", subtype: "mortgage", initial_balance: 85_000, interest_rate: 3.5, term_months: 240)
        car_loan = ensure_loan!("Leasing auta", subtype: "auto", initial_balance: 12_000, interest_rate: 5.9, term_months: 48)
        friend_loan = ensure_liability!("Pôžička od Martina", OtherLiability)

        6.downto(0) do |months_ago|
          month = months_ago.months.ago.to_date.beginning_of_month + 15.days
          next if month > Date.current

          checking.entries.create!(
            entryable: Transaction.new(category: category("Bývanie")),
            amount: 520,
            name: "Splátka hypotéky",
            currency: CURRENCY,
            date: month
          )

          mortgage.entries.create!(
            entryable: Transaction.new(category: category("Bývanie")),
            amount: -520,
            name: "Splátka hypotéky",
            currency: CURRENCY,
            date: month
          )

          checking.entries.create!(
            entryable: Transaction.new(category: category("Doprava")),
            amount: 280,
            name: "Splátka auta",
            currency: CURRENCY,
            date: month + 2.days
          )

          car_loan.entries.create!(
            entryable: Transaction.new(category: category("Doprava")),
            amount: -280,
            name: "Splátka auta",
            currency: CURRENCY,
            date: month + 2.days
          )
        end

        friend_loan.entries.create!(
          entryable: Transaction.new(category: category("Nákupy")),
          amount: 500,
          name: "Pôžičené peniaze",
          currency: CURRENCY,
          date: 3.months.ago.to_date
        )
      end

      def ensure_loan!(name, subtype:, initial_balance:, interest_rate:, term_months:)
        existing = @family.accounts.find_by(name: name)
        return existing if existing

        @family.accounts.create!(
          accountable: Loan.new(
            initial_balance: initial_balance,
            interest_rate: interest_rate,
            term_months: term_months,
            rate_type: "fixed"
          ),
          name: name,
          subtype: subtype,
          balance: initial_balance,
          cash_balance: 0,
          currency: CURRENCY
        )
      end

      def ensure_liability!(name, accountable_class)
        existing = @family.accounts.find_by(name: name)
        return existing if existing

        @family.accounts.create!(
          accountable: accountable_class.new,
          name: name,
          balance: 500,
          cash_balance: 0,
          currency: CURRENCY
        )
      end

      def create_investments!(account)
        start_date = 6.months.ago.to_date

        SECURITIES.each do |sec_data|
          security = Security.find_or_create_by!(ticker: sec_data[:ticker], exchange_operating_mic: nil) do |s|
            s.name = sec_data[:name]
            s.country_code = "SK"
            s.offline = true
          end

          ensure_security_prices!(security, sec_data[:price], start_date)

          qty = @rng.rand(3..15)
          trade_date = start_date + @rng.rand(0..30).days
          price = sec_data[:price]

          account.entries.create!(
            entryable: Trade.new(security: security, qty: qty, price: price, currency: CURRENCY),
            amount: qty * price,
            name: "Nákup #{security.ticker}",
            currency: CURRENCY,
            date: trade_date
          )
        end
      end

      def ensure_security_prices!(security, base_price, start_date)
        (start_date..Date.current).step(7) do |date|
          security.prices.find_or_create_by!(date: date, currency: CURRENCY) do |price|
            price.price = base_price + @rng.rand(-8..8)
          end
        end
      end

      def ensure_budget!
        budget = Budget.find_or_bootstrap(@family, start_date: Date.current)
        return unless budget

        budget.update!(
          expected_income: 3_000,
          budgeted_spending: 2_200
        )

        budget.budget_categories.find_each do |bc|
          next if bc.budgeted_spending.to_d.positive?

          bc.update!(budgeted_spending: case bc.category.name
          when "Potraviny" then 400
          when "Bývanie" then 600
          when "Doprava" then 150
          when "Zábava" then 100
          when "Predplatné" then 80
          when "Nákupy" then 200
          when "Reštaurácie" then 120
          when "Zdravie" then 60
          else 50
          end)
        end
      end

      def sync_accounts!(account_ids)
        accounts = @family.accounts.where(id: account_ids).to_a
        priority = accounts.find { |a| a.name == "Hlavný účet" } || accounts.first

        accounts.each do |account|
          if account == priority
            sync = Sync.create!(syncable: account)
            sync.perform
          else
            account.sync_later
          end
        rescue => e
          Rails.logger.error("Demo::Setup sync failed for account #{account.id}: #{e.class} - #{e.message}")
        end

        @family.auto_match_transfers!
      end
  end
end
