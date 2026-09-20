class Investment < ApplicationRecord
  include Accountable

  SUBTYPES = {
    "brokerage" => { short: "Brokerský", long: "Brokerský účet" },
    "pension" => { short: "II. pilier", long: "Starobné dôchodkové sporenie (II. pilier)" },
    "retirement" => { short: "III. pilier", long: "Doplnkové dôchodkové sporenie (III. pilier)" },
    "mutual_fund" => { short: "Podielový fond", long: "Podielový fond" }
  }.freeze

  class << self
    def color
      "#1570EF"
    end

    def classification
      "asset"
    end

    def icon
      "line-chart"
    end
  end
end
