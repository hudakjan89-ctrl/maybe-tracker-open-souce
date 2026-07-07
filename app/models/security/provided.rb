module Security::Provided
  extend ActiveSupport::Concern

  class_methods do
    def search_local(symbol, country_code: nil, exchange_operating_mic: nil)
      return [] if symbol.blank?

      scope = where("ticker ILIKE ?", "%#{symbol}%")
      scope = scope.where(country_code: country_code) if country_code.present?
      scope = scope.where(exchange_operating_mic: exchange_operating_mic) if exchange_operating_mic.present?
      scope.limit(20)
    end

    alias_method :search_provider, :search_local
  end

  def find_or_fetch_price(date: Date.current, cache: true)
    prices.find_by(date: date)
  end
end
