class Family < ApplicationRecord
  include Syncable, AutoTransferMatchable

  DATE_FORMATS = [
    [ "MM-DD-YYYY", "%m-%d-%Y" ],
    [ "DD.MM.YYYY", "%d.%m.%Y" ],
    [ "DD-MM-YYYY", "%d-%m-%Y" ],
    [ "YYYY-MM-DD", "%Y-%m-%d" ],
    [ "DD/MM/YYYY", "%d/%m/%Y" ],
    [ "YYYY/MM/DD", "%Y/%m/%d" ],
    [ "MM/DD/YYYY", "%m/%d/%Y" ],
    [ "D/MM/YYYY", "%e/%m/%Y" ],
    [ "YYYY.MM.DD", "%Y.%m.%d" ]
  ].freeze

  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :invitations, dependent: :destroy

  has_many :imports, dependent: :destroy
  has_many :family_exports, dependent: :destroy

  has_many :entries, through: :accounts
  has_many :transactions, through: :accounts
  has_many :rules, dependent: :destroy
  has_many :trades, through: :accounts
  has_many :holdings, through: :accounts

  has_many :tags, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :merchants, dependent: :destroy, class_name: "FamilyMerchant"

  has_many :budgets, dependent: :destroy
  has_many :budget_categories, through: :budgets

  attribute :locale, :string, default: "sk"

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :date_format, inclusion: { in: DATE_FORMATS.map(&:last) }

  def assigned_merchants
    merchant_ids = transactions.where.not(merchant_id: nil).pluck(:merchant_id).uniq
    Merchant.where(id: merchant_ids)
  end

  def balance_sheet
    @balance_sheet ||= BalanceSheet.new(self)
  end

  def income_statement
    @income_statement ||= IncomeStatement.new(self)
  end

  def eu?
    country != "US" && country != "CA"
  end

  def oldest_entry_date
    entries.order(:date).first&.date || Date.current
  end

  def default_cash_account
    cash = accounts.visible.where(accountable_type: "Depository").alphabetically.to_a
    cash.find { |account| account.name.match?(/hlavn|tatra|bežn|bezny|checking/i) } || cash.first || accounts.visible.alphabetically.first
  end

  # Zmaže splatené testovacie záväzky (napr. leasing) aj s anglickými
  # platbami „Payment to …“ na bežnom účte.
  def purge_leftover_liability_payments!
    leftover_name = /leasing|testovac|pr[ií]klad|sample|demo/i
    leftover_types = %w[Loan OtherLiability]

    accounts.where(status: "disabled", accountable_type: leftover_types).find_each do |liability|
      next unless liability.name.match?(leftover_name)
      next unless entries.exists?([ "name ILIKE ?", "Payment to #{self.class.sanitize_sql_like(liability.name)}%" ])

      liability.destroy!
    end

    entries.where("name ILIKE ?", "Payment to %").find_each do |entry|
      dest_name = entry.name.sub(/\APayment to /i, "").strip
      next unless dest_name.match?(leftover_name)

      dest = accounts.where(accountable_type: leftover_types).find_by("LOWER(name) = ?", dest_name.downcase)
      next if dest&.active? || dest&.draft?

      dest ? dest.destroy! : entry.destroy!
    end
  end

  # Used for invalidating family / balance sheet related aggregation queries
  def build_cache_key(key, invalidate_on_data_updates: false)
    # Our data sync process updates this timestamp whenever any family account successfully completes a data update.
    # By including it in the cache key, we can expire caches every time family account data changes.
    data_invalidation_key = invalidate_on_data_updates ? latest_sync_completed_at : nil

    [
      id,
      key,
      data_invalidation_key,
      accounts.maximum(:updated_at)
    ].compact.join("_")
  end

  # Used for invalidating entry related aggregation queries
  def entries_cache_version
    @entries_cache_version ||= begin
      ts = entries.maximum(:updated_at)
      ts.present? ? ts.to_i : 0
    end
  end

  def self_hoster?
    true
  end
end
