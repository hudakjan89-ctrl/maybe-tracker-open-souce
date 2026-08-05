module Demo
  class SampleTransactions
    SLOVAK_CATEGORIES = [
      [ "Príjem", "#e99537", "circle-dollar-sign", "income" ],
      [ "Potraviny", "#eb5429", "utensils", "expense" ],
      [ "Reštaurácie", "#df4e92", "utensils", "expense" ],
      [ "Nákupy", "#e99537", "shopping-cart", "expense" ],
      [ "Doprava", "#6471eb", "bus", "expense" ],
      [ "Zábava", "#df4e92", "drama", "expense" ],
      [ "Bývanie", "#6471eb", "house", "expense" ],
      [ "Zdravie", "#4da568", "pill", "expense" ],
      [ "Predplatné", "#805dee", "credit-card", "expense" ]
    ].freeze

    INCOME_NAMES = [ "Plat", "Bonus", "Freelance", "Dividendy", "Výplata" ].freeze
    EXPENSE_NAMES = [
      "Tesco", "Kaufland", "Lidl", "Bolt", "Netflix", "Spotify",
      "Benzín", "Nájom", "Elektrina", "Vodafone", "Apple", "Amazon",
      "Starbucks", "McDonald's", "IKEA", "DM drogéria"
    ].freeze

    SECURITIES = [
      { ticker: "VWCE", name: "Vanguard FTSE All-World UCITS ETF" },
      { ticker: "SXR8", name: "iShares Core S&P 500 UCITS ETF" },
      { ticker: "EUNL", name: "iShares Core MSCI World UCITS ETF" }
    ].freeze

    def initialize(family)
      @family = family
    end

    def generate!
      ensure_categories!
      checking = ensure_checking_account!
      investment = ensure_investment_account!

      create_sample_transactions!(checking)
      create_sample_investments!(investment)

      @family.accounts.each(&:sync_later)
    end

    private

      def ensure_categories!
        return if @family.categories.any?

        SLOVAK_CATEGORIES.each do |name, color, icon, classification|
          @family.categories.create!(
            name: name,
            color: color,
            lucide_icon: icon,
            classification: classification
          )
        end
      end

      def ensure_checking_account!
        account = @family.accounts.where(accountable_type: "Depository").first
        return account if account

        Account.create_and_sync(
          family: @family,
          name: "Hlavný účet",
          balance: 5_000,
          currency: @family.currency,
          accountable: Depository.new(subtype: "checking")
        )
      end

      def ensure_investment_account!
        account = @family.accounts.where(accountable_type: "Investment").first
        return account if account

        Account.create_and_sync(
          family: @family,
          name: "Investičný portfólio",
          balance: 10_000,
          currency: @family.currency,
          accountable: Investment.new(subtype: "brokerage")
        )
      end

      def create_sample_transactions!(account)
        income_cat = @family.categories.incomes.first
        expense_cats = @family.categories.expenses.to_a

        40.times do
          date = rand(6.months.ago.to_date..Date.current)
          is_income = rand < 0.25

          if is_income
            amount = -rand(800..3_500)
            name = INCOME_NAMES.sample
            category = income_cat
          else
            amount = rand(5..250)
            name = EXPENSE_NAMES.sample
            category = expense_cats.sample
          end

          account.entries.create!(
            entryable: Transaction.new(category: category),
            amount: amount,
            name: name,
            currency: account.currency,
            date: date
          )
        end
      end

      def create_sample_investments!(account)
        SECURITIES.each do |sec_data|
          security = Security.find_or_create_by!(ticker: sec_data[:ticker]) do |s|
            s.name = sec_data[:name]
            s.country_code = "SK"
          end

          qty = rand(1..20)
          price = rand(50..400)

          account.entries.create!(
            entryable: Trade.new(security: security, qty: qty, price: price, currency: account.currency),
            amount: -(qty * price),
            name: "Nákup #{security.ticker}",
            currency: account.currency,
            date: rand(6.months.ago.to_date..Date.current)
          )
        end
      end
  end
end
