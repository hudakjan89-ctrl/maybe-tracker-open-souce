class ChartsController < ApplicationController
  include Periodable

  def index
    @chart_data = Current.family.income_statement.monthly_series(period: @period)
    @currency_symbol = Money::Currency.new(Current.family.currency).symbol

    @breadcrumbs = [ [ "Domov", root_path ], [ "Grafy", nil ] ]
  end
end
