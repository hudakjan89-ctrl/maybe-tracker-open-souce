class PagesController < ApplicationController
  include Periodable

  skip_authentication only: :redis_configuration_error

  def dashboard
    period_param = params[:cashflow_period]
    @cashflow_period = if period_param.present?
      begin
        Period.from_key(period_param)
      rescue Period::InvalidKeyError
        Period.last_30_days
      end
    else
      Period.last_30_days
    end

    month_period = Period.current_month
    @month_income = Current.family.income_statement.income_totals(period: month_period)
    @month_expense = Current.family.income_statement.expense_totals(period: month_period)
    @spending_income = Current.family.income_statement.income_totals(period: @cashflow_period)
    @spending_expense = Current.family.income_statement.expense_totals(period: @cashflow_period)

    @recent_entries = Current.family.entries
      .includes(entryable: [ :category, :merchant ])
      .visible
      .reverse_chronological
      .limit(8)
    @current_budget = Budget.find_or_bootstrap(Current.family, start_date: Date.current)
    @dashboard = Dashboard::Overview.new(Current.family)

    @breadcrumbs = [ [ "Domov", root_path ], [ "Prehľad", nil ] ]
  end

  def redis_configuration_error
    render layout: "blank"
  end
end
