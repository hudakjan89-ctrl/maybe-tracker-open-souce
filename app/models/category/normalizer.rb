# Preklad a upratanie leftover anglických kategórií z pôvodného Maybe.
class Category::Normalizer
  RENAME = {
    "Income" => "Plat",
    "Paycheck" => "Plat",
    "Salary" => "Plat",
    "Housing" => "Bývanie",
    "Rent" => "Bývanie",
    "Transportation" => "Doprava",
    "Transport" => "Doprava",
    "Food & Drink" => "Potraviny",
    "Food and Drink" => "Potraviny",
    "Groceries" => "Potraviny",
    "Shopping" => "Nákupy",
    "Subscriptions" => "Predplatné",
    "Entertainment" => "Zábava",
    "Healthcare" => "Zdravie",
    "Health" => "Zdravie",
    "Restaurants" => "Reštaurácie",
    "Dining" => "Reštaurácie",
    "Coffee" => "Reštaurácie",
    "Fees" => "Poplatky",
    "Gifts & Donations" => "Dary",
    "Gifts and Donations" => "Dary",
    "Travel" => "Cestovanie",
    "Utilities" => "Bývanie",
    "Personal" => "Nákupy",
    "Education" => "Vzdelávanie",
    "Childcare" => "Deti",
    "Pets" => "Zvieratá",
    "Insurance" => "Poistenie",
    "Investment Income" => "Príjem"
  }.freeze

  UNUSED_ENGLISH = %w[
    Income Housing Transportation Shopping Entertainment Fees
    Travel Utilities Personal Education Childcare Pets Insurance
    Healthcare Health Groceries Dining Coffee Paycheck Salary
  ].freeze

  def initialize(family)
    @family = family
  end

  def normalize!
    rename_legacy!
    merge_duplicates!
    remove_unused_english!
    Category.where(family_id: @family.id).bootstrap!
  end

  class << self
    def normalize!(family)
      new(family).normalize!
    end
  end

  private

    def rename_legacy!
      @family.categories.find_each do |category|
        slovak = RENAME[category.name]
        next unless slovak
        next if @family.categories.exists?(name: slovak)

        category.update!(name: slovak)
      end
    end

    def merge_duplicates!
      RENAME.each do |english, slovak|
        leftover = @family.categories.find_by(name: english)
        target = @family.categories.find_by(name: slovak)
        next unless leftover && target && leftover.id != target.id

        leftover.transactions.update_all(category_id: target.id)
        leftover.budget_categories.destroy_all
        leftover.destroy!
      end
    end

    def remove_unused_english!
      @family.categories.where(name: UNUSED_ENGLISH + RENAME.keys).find_each do |category|
        next if category.transactions.exists?

        category.budget_categories.destroy_all
        category.destroy!
      end
    end
end
