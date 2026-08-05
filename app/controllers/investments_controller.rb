class InvestmentsController < ApplicationController
  include AccountableResource

  def index
    @investment_accounts = Current.family.accounts
      .where(accountable_type: "Investment")
      .visible
      .with_attached_logo
      .alphabetically

    @total_value = @investment_accounts.sum(&:balance)
    @currency = Current.family.currency

    @breadcrumbs = [ [ "Domov", root_path ], [ "Investície", nil ] ]
  end
end
