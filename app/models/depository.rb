class Depository < ApplicationRecord
  include Accountable

  SUBTYPES = {
    "checking" => { short: "Bežný", long: "Bežný účet" },
    "savings" => { short: "Sporiaci", long: "Sporiaci účet" },
    "cd" => { short: "Termínovaný", long: "Termínovaný vklad" },
    "money_market" => { short: "Peňažný trh", long: "Fond peňažného trhu" }
  }.freeze

  class << self
    def display_name
      "Hotovosť"
    end

    def color
      "#875BF7"
    end

    def classification
      "asset"
    end

    def icon
      "landmark"
    end
  end
end
