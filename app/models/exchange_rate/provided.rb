module ExchangeRate::Provided
  extend ActiveSupport::Concern

  class_methods do
    def find_or_fetch_rate(from:, to:, date: Date.current, cache: true)
      return find_or_create_by!(from_currency: from, to_currency: to, date: date, rate: 1) if from == to

      find_by(from_currency: from, to_currency: to, date: date)
    end
  end
end
