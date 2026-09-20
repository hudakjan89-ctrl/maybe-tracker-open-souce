class Valuation::Name
  def initialize(valuation_kind, accountable_type)
    @valuation_kind = valuation_kind
    @accountable_type = accountable_type
  end

  def to_s
    case valuation_kind
    when "opening_anchor"
      opening_anchor_name
    when "current_anchor"
      current_anchor_name
    else
      recon_name
    end
  end

  private
    attr_reader :valuation_kind, :accountable_type

    def opening_anchor_name
      case accountable_type
      when "Property", "Vehicle"
        "Pôvodná kúpna cena"
      when "Loan"
        "Pôvodná istina"
      when "Investment", "Crypto", "OtherAsset"
        "Počiatočná hodnota účtu"
      else
        "Počiatočný zostatok"
      end
    end

    def current_anchor_name
      case accountable_type
      when "Property", "Vehicle"
        "Aktuálna trhová hodnota"
      when "Loan"
        "Aktuálny zostatok úveru"
      when "Investment", "Crypto", "OtherAsset"
        "Aktuálna hodnota účtu"
      else
        "Aktuálny zostatok"
      end
    end

    def recon_name
      case accountable_type
      when "Property", "Investment", "Vehicle", "Crypto", "OtherAsset"
        "Manuálna úprava hodnoty"
      when "Loan"
        "Manuálna úprava istiny"
      else
        "Manuálna úprava zostatku"
      end
    end
end
