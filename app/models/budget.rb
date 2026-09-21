class Budget < ApplicationRecord
  include Monetizable

  # Locale-stable URL param (old links like "sep-2026" still parse).
  PARAM_DATE_FORMAT = "%Y-%m"
  LEGACY_PARAM_FORMATS = [ "%b-%Y", "%B-%Y", "%m-%Y", "%Y-%m-%d" ].freeze

  belongs_to :family

  has_many :budget_categories, -> { includes(:category) }, dependent: :destroy

  validates :start_date, :end_date, presence: true
  validates :start_date, uniqueness: { scope: :family_id }

  monetize :budgeted_spending, :expected_income, :allocated_spending,
           :actual_spending, :available_to_spend, :available_to_allocate,
           :estimated_spending, :estimated_income, :actual_income, :remaining_expected_income

  class << self
    def date_to_param(date)
      date.to_date.strftime(PARAM_DATE_FORMAT)
    end

    def param_to_date(param)
      str = param.to_s.strip
      return Date.current.beginning_of_month if str.blank?

      ( [ PARAM_DATE_FORMAT ] + LEGACY_PARAM_FORMATS ).each do |fmt|
        begin
          return Date.strptime(str, fmt).beginning_of_month
        rescue ArgumentError, Date::Error
          next
        end
      end

      Date.current.beginning_of_month
    end

    def budget_date_valid?(date, family:)
      beginning_of_month = date.to_date.beginning_of_month

      beginning_of_month >= oldest_valid_budget_date(family) && beginning_of_month <= Date.current.end_of_month
    end

    def find_or_bootstrap(family, start_date:)
      date = start_date.to_date.beginning_of_month
      return nil unless budget_date_valid?(date, family: family)

      Budget.transaction do
        budget = family.budgets.find_by(start_date: date) || family.budgets.create!(
          start_date: date,
          end_date: date.end_of_month,
          currency: family.currency.presence || "EUR"
        )

        budget.sync_budget_categories
        budget.budget_categories.reset
        budget
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      family.budgets.find_by(start_date: date)&.tap(&:sync_budget_categories)
    end

    private
      def oldest_valid_budget_date(family)
        # Allow going back to either the earliest entry date OR 2 years ago, whichever is earlier
        two_years_ago = 2.years.ago.beginning_of_month
        oldest_entry_date = family.oldest_entry_date.beginning_of_month
        [ two_years_ago, oldest_entry_date ].min
      end
  end

  def period
    Period.custom(start_date: start_date, end_date: end_date)
  end

  def to_param
    self.class.date_to_param(start_date)
  end

  def sync_budget_categories
    current_category_ids = family.categories.expenses.pluck(:id).to_set
    existing_budget_category_ids = budget_categories.pluck(:category_id).to_set
    categories_to_add = current_category_ids - existing_budget_category_ids
    categories_to_remove = existing_budget_category_ids - current_category_ids

    # Create missing categories
    categories_to_add.each do |category_id|
      budget_categories.create!(
        category_id: category_id,
        budgeted_spending: 0,
        currency: family.currency
      )
    end

    # Remove old categories
    budget_categories.where(category_id: categories_to_remove).destroy_all if categories_to_remove.any?
  end

  def uncategorized_budget_category
    BudgetCategory.uncategorized.tap do |bc|
      bc.budget = self
      bc.budgeted_spending = [ available_to_allocate, 0 ].max
      bc.currency = family.currency
    end
  end

  def transactions
    family.transactions.visible.in_period(period)
  end

  def name
    start_date.strftime("%B %Y")
  end

  def initialized?
    budgeted_spending.present?
  end

  def income_category_totals
    income_totals.category_totals.reject { |ct| ct.category.subcategory? || ct.total.zero? }.sort_by(&:weight).reverse
  end

  def expense_category_totals
    expense_totals.category_totals.reject { |ct| ct.category.subcategory? || ct.total.zero? }.sort_by(&:weight).reverse
  end

  def current?
    start_date == Date.today.beginning_of_month && end_date == Date.today.end_of_month
  end

  def previous_budget_param
    previous_date = start_date - 1.month
    return nil unless self.class.budget_date_valid?(previous_date, family: family)

    self.class.date_to_param(previous_date)
  end

  def next_budget_param
    return nil if current?

    next_date = start_date + 1.month
    return nil unless self.class.budget_date_valid?(next_date, family: family)

    self.class.date_to_param(next_date)
  end

  def to_donut_segments_json
    unused_segment_id = "unused"

    # Continuous gray segment for empty budgets
    return [ { color: "var(--budget-unallocated-fill)", amount: 1, id: unused_segment_id } ] unless allocations_valid?

    segments = budget_categories.filter_map do |bc|
      next unless bc.category

      { color: bc.category.color, amount: budget_category_actual_spending(bc), id: bc.id }
    end

    if available_to_spend.positive?
      segments.push({ color: "var(--budget-unallocated-fill)", amount: available_to_spend, id: unused_segment_id })
    end

    segments
  end

  # =============================================================================
  # Actuals: How much user has spent on each budget category
  # =============================================================================
  def estimated_spending
    income_statement.median_expense(interval: "month")
  end

  def actual_spending
    expense_totals.total
  end

  def budget_category_actual_spending(budget_category)
    category = budget_category.category
    return 0 unless category

    expense_totals.category_totals.find { |ct| ct.category&.id == category.id }&.total || 0
  end

  def category_median_monthly_expense(category)
    income_statement.median_expense(category: category)
  end

  def category_avg_monthly_expense(category)
    income_statement.avg_expense(category: category)
  end

  def available_to_spend
    (budgeted_spending || 0) - actual_spending
  end

  def percent_of_budget_spent
    return 0 unless budgeted_spending.to_d.positive?

    (actual_spending.to_d / budgeted_spending.to_d) * 100
  end

  def overage_percent
    return 0 unless available_to_spend.negative?
    return 0 unless actual_spending.to_d.positive?

    available_to_spend.abs / actual_spending.to_d * 100
  end

  # =============================================================================
  # Budget allocations: How much user has budgeted for all parent categories combined
  # =============================================================================
  def allocated_spending
    budget_categories.reject(&:subcategory?).sum { |bc| bc.budgeted_spending.to_d }
  end

  def allocated_percent
    return 0 unless budgeted_spending.to_d.positive?

    (allocated_spending / budgeted_spending.to_d) * 100
  end

  def available_to_allocate
    (budgeted_spending || 0) - allocated_spending
  end

  def allocations_valid?
    initialized? && available_to_allocate >= 0 && allocated_spending > 0
  end

  # =============================================================================
  # Income: How much user earned relative to what they expected to earn
  # =============================================================================
  def estimated_income
    family.income_statement.median_income(interval: "month")
  end

  def actual_income
    family.income_statement.income_totals(period: self.period).total
  end

  def actual_income_percent
    return 0 unless expected_income.to_d.positive?

    (actual_income.to_d / expected_income.to_d) * 100
  end

  def remaining_expected_income
    expected_income.to_d - actual_income.to_d
  end

  def surplus_percent
    return 0 unless remaining_expected_income.negative?
    return 0 unless expected_income.to_d.positive?

    remaining_expected_income.abs / expected_income.to_d * 100
  end

  private
    def income_statement
      @income_statement ||= family.income_statement
    end

    def expense_totals
      @expense_totals ||= income_statement.expense_totals(period: period)
    end

    def income_totals
      @income_totals ||= family.income_statement.income_totals(period: period)
    end
end
