module Breadcrumbable
  extend ActiveSupport::Concern

  included do
    before_action :set_breadcrumbs
  end

  private
    # The default, unless specific controller or action explicitly overrides
    def set_breadcrumbs
      @breadcrumbs = [ [ "Domov", root_path ], [ breadcrumb_label_for(controller_name), nil ] ]
    end

    def breadcrumb_label_for(name)
      {
        "transactions" => "Transakcie",
        "accounts" => "Účty",
        "budgets" => "Rozpočty",
        "budget_categories" => "Rozpočty",
        "charts" => "Grafy",
        "investments" => "Investície",
        "holdings" => "Držby",
        "imports" => "Importy",
        "tatra_statements" => "Výpis Tatra banky",
        "categories" => "Kategórie",
        "tags" => "Značky",
        "rules" => "Pravidlá",
        "family_merchants" => "Obchodníci",
        "merchants" => "Obchodníci",
        "liabilities" => "Záväzky",
        "settings" => "Nastavenia",
        "pages" => "Prehľad"
      }.fetch(name, name.tr("_", " ").capitalize)
    end
end
