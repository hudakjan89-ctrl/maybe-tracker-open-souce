module ImportsHelper
  def mapping_label(mapping_class)
    {
      "Import::AccountTypeMapping" => "Typ účtu",
      "Import::AccountMapping" => "Účet",
      "Import::CategoryMapping" => "Kategória",
      "Import::TagMapping" => "Značka"
    }.fetch(mapping_class.name)
  end

  def import_col_label(key)
    {
      date: "Dátum",
      amount: "Suma",
      name: "Názov",
      currency: "Mena",
      category: "Kategória",
      tags: "Značky",
      account: "Účet",
      notes: "Poznámky",
      qty: "Množstvo",
      ticker: "Ticker",
      exchange: "Burza",
      price: "Cena",
      entity_type: "Typ"
    }[key]
  end

  def dry_run_resource(key)
    map = {
      transactions: DryRunResource.new(label: "Transakcie", icon: "credit-card", text_class: "text-cyan-500", bg_class: "bg-cyan-500/5"),
      accounts: DryRunResource.new(label: "Účty", icon: "layers", text_class: "text-orange-500", bg_class: "bg-orange-500/5"),
      categories: DryRunResource.new(label: "Kategórie", icon: "shapes", text_class: "text-blue-500", bg_class: "bg-blue-500/5"),
      tags: DryRunResource.new(label: "Značky", icon: "tags", text_class: "text-violet-500", bg_class: "bg-violet-500/5")
    }

    map[key]
  end

  def permitted_import_configuration_path(import)
    if permitted_import_types.include?(import.type.underscore)
      "import/configurations/#{import.type.underscore}"
    else
      raise "Unknown import type: #{import.type}"
    end
  end

  def cell_class(row, field)
    base = "bg-container text-sm focus:ring-gray-900 theme-dark:focus:ring-gray-100 focus:border-solid w-full max-w-full disabled:text-subdued"

    row.valid? # populate errors

    border = row.errors.key?(field) ? "border-destructive" : "border-transparent"

    [ base, border ].join(" ")
  end

  def cell_is_valid?(row, field)
    row.valid? # populate errors
    !row.errors.key?(field)
  end

  private
    def permitted_import_types
      %w[transaction_import trade_import account_import mint_import]
    end

    DryRunResource = Struct.new(:label, :icon, :text_class, :bg_class, keyword_init: true)
end
