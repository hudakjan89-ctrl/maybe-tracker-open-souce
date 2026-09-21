class BudgetCategory < ApplicationRecord
  include Monetizable

  belongs_to :budget
  belongs_to :category

  validates :budget_id, uniqueness: { scope: :category_id }

  monetize :budgeted_spending, :available_to_spend, :avg_monthly_expense, :median_monthly_expense, :actual_spending

  # Koľko kategórií ukážeme hneď; zvyšok sa skryje za rozbaľovacie tlačidlo.
  VISIBLE_LIMIT = 5

  class Group
    attr_reader :budget_category, :budget_subcategories

    delegate :category, to: :budget_category
    delegate :name, :color, to: :category

    def self.for(budget_categories)
      top_level_categories = budget_categories.select { |budget_category| budget_category.category.present? && budget_category.category.parent_id.nil? }
      top_level_categories.map do |top_level_category|
        subcategories = budget_categories.select { |bc| bc.category.parent_id == top_level_category.category_id && top_level_category.category_id.present? }
        new(top_level_category, subcategories.sort_by { |subcategory| subcategory.category.name })
      end.sort_by { |group| group.category.name }
    end

    # Najdôležitejšie kategórie ako prvé: tie, do ktorých už používateľ rozdelil
    # peniaze, potom tie, v ktorých v minulosti najviac míňal.
    def self.by_relevance(budget_categories)
      self.for(budget_categories).sort_by do |group|
        [
          group.budgeted? ? 0 : 1,
          -group.typical_monthly_expense,
          group.name
        ]
      end
    end

    # Prvých VISIBLE_LIMIT skupín a zvyšok, ktorý sa skryje za rozbalenie.
    def self.split_by_relevance(budget_categories, limit: VISIBLE_LIMIT)
      groups = by_relevance(budget_categories)
      [ groups.first(limit), groups.drop(limit) ]
    end

    def initialize(budget_category, budget_subcategories = [])
      @budget_category = budget_category
      @budget_subcategories = budget_subcategories
    end

    def budgeted?
      (budget_category.budgeted_spending || 0).to_d.positive?
    end

    def typical_monthly_expense
      (budget_category.median_monthly_expense || 0).to_d
    end
  end

  class << self
    def uncategorized
      new(
        id: Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "uncategorized"),
        category: nil,
      )
    end
  end

  def initialized?
    budget&.initialized?
  end

  def category
    super || budget&.family&.categories&.uncategorized || Category.uncategorized
  end

  def name
    category.name
  end

  def actual_spending
    return 0 unless budget

    budget.budget_category_actual_spending(self)
  end

  def avg_monthly_expense
    return 0 unless budget

    budget.category_avg_monthly_expense(category)
  end

  def median_monthly_expense
    return 0 unless budget

    budget.category_median_monthly_expense(category)
  end

  def subcategory?
    category.parent_id.present?
  end

  def available_to_spend
    (budgeted_spending || 0) - actual_spending
  end

  def percent_of_budget_spent
    return 0 unless budgeted_spending.to_d.positive?

    (actual_spending.to_d / budgeted_spending.to_d) * 100
  end

  def to_donut_segments_json
    unused_segment_id = "unused"
    overage_segment_id = "overage"

    return [ { color: "var(--budget-unallocated-fill)", amount: 1, id: unused_segment_id } ] unless actual_spending > 0

    segments = [ { color: category.color, amount: actual_spending, id: id } ]

    if available_to_spend.negative?
      segments.push({ color: "var(--color-destructive)", amount: available_to_spend.abs, id: overage_segment_id })
    else
      segments.push({ color: "var(--budget-unallocated-fill)", amount: available_to_spend, id: unused_segment_id })
    end

    segments
  end

  def siblings
    budget.budget_categories.select { |bc| bc.category.parent_id == category.parent_id && bc.id != id }
  end

  def max_allocation
    return nil unless subcategory?

    parent_budget = budget.budget_categories.find { |bc| bc.category.id == category.parent_id }&.budgeted_spending
    siblings_budget = siblings.sum { |s| s.budgeted_spending.to_d }

    [ parent_budget - siblings_budget, 0 ].max
  end

  def subcategories
    return BudgetCategory.none unless category.parent_id.nil?

    budget.budget_categories
      .joins(:category)
      .where(categories: { parent_id: category.id })
  end

  def subcategory?
    category.parent_id.present?
  end
end
