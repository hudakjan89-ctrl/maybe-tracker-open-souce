module TransactionsHelper
  TRANSACTION_PERIODS = [
    { key: "last_7_days", label: "7 dní" },
    { key: "last_30_days", label: "30 dní" },
    { key: "last_90_days", label: "90 dní" },
    { key: "current_month", label: "Mesiac" },
    { key: "current_year", label: "Rok" },
    { key: "all", label: "Všetko" }
  ].freeze

  def transaction_search_filters
    [
      { key: "account_filter", label: "Účet", icon: "layers" },
      { key: "date_filter", label: "Dátum", icon: "calendar" },
      { key: "type_filter", label: "Typ", icon: "tag" },
      { key: "amount_filter", label: "Suma", icon: "hash" },
      { key: "category_filter", label: "Kategória", icon: "shapes" },
      { key: "tag_filter", label: "Značka", icon: "tags" },
      { key: "merchant_filter", label: "Obchodník", icon: "store" }
    ]
  end

  def get_transaction_search_filter_partial_path(filter)
    "transactions/searches/filters/#{filter[:key]}"
  end

  def get_default_transaction_search_filter
    transaction_search_filters[0]
  end

  def transaction_period_key(filters = @q)
    start_date, end_date = transaction_filter_dates(filters)
    return "all" if start_date.blank? && end_date.blank?

    TRANSACTION_PERIODS.each do |option|
      next if option[:key] == "all"

      period = Period.from_key(option[:key])
      return option[:key] if period.start_date == start_date && period.end_date == end_date
    end

    "custom"
  rescue ArgumentError, Date::Error
    "custom"
  end

  def transaction_period_url(period_key, filters: @q)
    q = (filters || {}).deep_dup.stringify_keys
    q.delete("start_date")
    q.delete("end_date")

    unless period_key.to_s == "all"
      period = Period.from_key(period_key.to_s)
      q["start_date"] = period.start_date
      q["end_date"] = period.end_date
    end

    transactions_path(q: q.compact_blank, per_page: params[:per_page])
  end

  def transaction_period_subtitle(filters = @q)
    key = transaction_period_key(filters)
    start_date, end_date = transaction_filter_dates(filters)

    case key
    when "all"
      "Všetky transakcie"
    when "custom"
      "Vlastné obdobie · #{transaction_date_range_label(start_date, end_date)}"
    else
      period = Period.from_key(key)
      "#{period.label} · #{transaction_date_range_label(period.start_date, period.end_date)}"
    end
  end

  def transaction_preset_period?(filters = @q)
    %w[all custom].exclude?(transaction_period_key(filters))
  end

  def transaction_net_money(totals)
    amount = totals.income_money.amount.to_d - totals.expense_money.amount.to_d
    Money.new(amount, totals.income_money.currency.iso_code)
  end

  def transaction_date_range_label_for_filters(filters = @q)
    start_date, end_date = transaction_filter_dates(filters)
    transaction_date_range_label(start_date, end_date)
  end

  private
    def transaction_filter_dates(filters)
      filters = (filters || {}).stringify_keys
      [ filters["start_date"].presence&.to_date, filters["end_date"].presence&.to_date ]
    end

    def transaction_date_range_label(start_date, end_date)
      return l(end_date) if start_date.blank?
      return l(start_date) if end_date.blank?

      "#{l(start_date)} – #{l(end_date)}"
    end
end
