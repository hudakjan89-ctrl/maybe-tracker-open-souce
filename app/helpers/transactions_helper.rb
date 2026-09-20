module TransactionsHelper
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
end
