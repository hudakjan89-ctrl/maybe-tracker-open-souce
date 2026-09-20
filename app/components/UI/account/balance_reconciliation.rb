class UI::Account::BalanceReconciliation < ApplicationComponent
  attr_reader :balance, :account

  def initialize(balance:, account:)
    @balance = balance
    @account = account
  end

  def reconciliation_items
    case account.accountable_type
    when "Depository", "OtherAsset", "OtherLiability"
      default_items
    when "CreditCard"
      credit_card_items
    when "Investment"
      investment_items
    when "Loan"
      loan_items
    when "Property", "Vehicle"
      asset_items
    when "Crypto"
      crypto_items
    else
      default_items
    end
  end

  private

    def default_items
      items = [
        { label: "Počiatočný zostatok", value: balance.start_balance_money, tooltip: "Zostatok na účte na začiatku tohto dňa", style: :start },
        { label: "Čistý tok hotovosti", value: net_cash_flow, tooltip: "Čistá zmena zostatku zo všetkých transakcií počas dňa", style: :flow }
      ]

      if has_adjustments?
        items << { label: "Vypočítaný zostatok", value: end_balance_before_adjustments, tooltip: "Zostatok vypočítaný po všetkých transakciách", style: :subtotal }
        items << { label: "Úpravy", value: total_adjustments, tooltip: "Ručné úpravy alebo iné korekcie", style: :adjustment }
      end

      items << { label: "Konečný zostatok", value: balance.end_balance_money, tooltip: "Konečný zostatok na účte za tento deň", style: :final }
      items
    end

    def credit_card_items
      items = [
        { label: "Počiatočný zostatok", value: balance.start_balance_money, tooltip: "Dlžná suma na začiatku tohto dňa", style: :start },
        { label: "Platby kartou", value: balance.cash_outflows_money, tooltip: "Nové platby kartou uskutočnené počas dňa", style: :flow },
        { label: "Splátky", value: balance.cash_inflows_money * -1, tooltip: "Splátky uhradené na kartu počas dňa", style: :flow }
      ]

      if has_adjustments?
        items << { label: "Vypočítaný zostatok", value: end_balance_before_adjustments, tooltip: "Zostatok vypočítaný po všetkých transakciách", style: :subtotal }
        items << { label: "Úpravy", value: total_adjustments, tooltip: "Ručné úpravy alebo iné korekcie", style: :adjustment }
      end

      items << { label: "Konečný zostatok", value: balance.end_balance_money, tooltip: "Konečná dlžná suma za tento deň", style: :final }
      items
    end

    def investment_items
      items = [
        { label: "Počiatočný zostatok", value: balance.start_balance_money, tooltip: "Celková hodnota portfólia na začiatku tohto dňa", style: :start }
      ]

      # Change in brokerage cash (includes deposits, withdrawals, and cash from trades)
      items << { label: "Zmena hotovosti na účte", value: net_cash_flow, tooltip: "Čistá zmena hotovosti z vkladov, výberov a obchodov", style: :flow }

      # Change in holdings from trading activity
      items << { label: "Zmena držieb (nákupy/predaje)", value: net_non_cash_flow, tooltip: "Vplyv nákupu a predaja cenných papierov na držby", style: :flow }

      # Market price changes
      items << { label: "Zmena držieb (pohyb trhových cien)", value: balance.net_market_flows_money, tooltip: "Zmena hodnoty držieb v dôsledku pohybu trhových cien", style: :flow }

      if has_adjustments?
        items << { label: "Vypočítaný zostatok", value: end_balance_before_adjustments, tooltip: "Zostatok vypočítaný po všetkých pohyboch", style: :subtotal }
        items << { label: "Úpravy", value: total_adjustments, tooltip: "Ručné úpravy alebo iné korekcie", style: :adjustment }
      end

      items << { label: "Konečný zostatok", value: balance.end_balance_money, tooltip: "Konečná hodnota portfólia za tento deň", style: :final }
      items
    end

    def loan_items
      items = [
        { label: "Počiatočná istina", value: balance.start_balance_money, tooltip: "Zostatok istiny na začiatku tohto dňa", style: :start },
        { label: "Čistá zmena istiny", value: net_non_cash_flow, tooltip: "Splátky istiny a nové čerpanie úveru počas dňa", style: :flow }
      ]

      if has_adjustments?
        items << { label: "Vypočítaná istina", value: end_balance_before_adjustments, tooltip: "Istina vypočítaná po všetkých transakciách", style: :subtotal }
        items << { label: "Úpravy", value: balance.non_cash_adjustments_money, tooltip: "Ručné úpravy alebo iné korekcie", style: :adjustment }
      end

      items << { label: "Konečná istina", value: balance.end_balance_money, tooltip: "Konečný zostatok istiny za tento deň", style: :final }
      items
    end

    def asset_items # Property/Vehicle
      items = [
        { label: "Počiatočná hodnota", value: balance.start_balance_money, tooltip: "Hodnota aktíva na začiatku tohto dňa", style: :start },
        { label: "Čistá zmena hodnoty", value: net_total_flow, tooltip: "Všetky zmeny hodnoty vrátane zhodnotenia a odpisov", style: :flow }
      ]

      if has_adjustments?
        items << { label: "Vypočítaná hodnota", value: end_balance_before_adjustments, tooltip: "Hodnota vypočítaná po všetkých zmenách", style: :subtotal }
        items << { label: "Úpravy", value: total_adjustments, tooltip: "Ručné úpravy hodnoty alebo odhady", style: :adjustment }
      end

      items << { label: "Konečná hodnota", value: balance.end_balance_money, tooltip: "Konečná hodnota aktíva za tento deň", style: :final }
      items
    end

    def crypto_items
      items = [
        { label: "Počiatočný zostatok", value: balance.start_balance_money, tooltip: "Hodnota kryptomien na začiatku tohto dňa", style: :start }
      ]

      items << { label: "Nákupy", value: balance.cash_outflows_money * -1, tooltip: "Nákupy kryptomien počas dňa", style: :flow } if balance.cash_outflows != 0
      items << { label: "Predaje", value: balance.cash_inflows_money, tooltip: "Predaje kryptomien počas dňa", style: :flow } if balance.cash_inflows != 0
      items << { label: "Zmeny na trhu", value: balance.net_market_flows_money, tooltip: "Zmeny hodnoty v dôsledku pohybu trhových cien", style: :flow } if balance.net_market_flows != 0

      if has_adjustments?
        items << { label: "Vypočítaný zostatok", value: end_balance_before_adjustments, tooltip: "Zostatok vypočítaný po všetkých pohyboch", style: :subtotal }
        items << { label: "Úpravy", value: total_adjustments, tooltip: "Ručné úpravy alebo iné korekcie", style: :adjustment }
      end

      items << { label: "Konečný zostatok", value: balance.end_balance_money, tooltip: "Konečná hodnota kryptomien za tento deň", style: :final }
      items
    end

    def net_cash_flow
      balance.cash_inflows_money - balance.cash_outflows_money
    end

    def net_non_cash_flow
      balance.non_cash_inflows_money - balance.non_cash_outflows_money
    end

    def net_total_flow
      net_cash_flow + net_non_cash_flow + balance.net_market_flows_money
    end

    def total_adjustments
      balance.cash_adjustments_money + balance.non_cash_adjustments_money
    end

    def has_adjustments?
      balance.cash_adjustments != 0 || balance.non_cash_adjustments != 0
    end

    def end_balance_before_adjustments
      balance.end_balance_money - total_adjustments
    end
end
