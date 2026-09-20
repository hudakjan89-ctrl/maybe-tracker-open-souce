class UI::Account::Chart < ApplicationComponent
  attr_reader :account

  def initialize(account:, period: nil, view: nil)
    @account = account
    @period = period
    @view = view
  end

  def period
    @period ||= Period.last_30_days
  end

  def holdings_value_money
    account.balance_money - account.cash_balance_money
  end

  def view_balance_money
    case view
    when "balance"
      account.balance_money
    when "holdings_balance"
      holdings_value_money
    when "cash_balance"
      account.cash_balance_money
    end
  end

  def title
    case account.accountable_type
    when "Investment", "Crypto"
      case view
      when "balance"
        "Celková hodnota účtu"
      when "holdings_balance"
        "Hodnota držieb"
      when "cash_balance"
        "Hodnota hotovosti"
      end
    when "Property"
      "Odhadovaná hodnota nehnuteľnosti"
    when "Vehicle"
      "Odhadovaná hodnota vozidla"
    when "CreditCard", "OtherLiability"
      "Zostatok dlhu"
    when "Loan"
      "Zostatok istiny"
    else
      "Zostatok"
    end
  end

  def foreign_currency?
    account.currency != account.family.currency
  end

  def converted_balance_money
    return nil unless foreign_currency?

    account.balance_money.exchange_to(account.family.currency, fallback_rate: 1)
  end

  def view
    @view ||= "balance"
  end

  def series
    account.balance_series(period: period, view: view)
  end

  def trend
    series.trend
  end
end
