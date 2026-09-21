class Account < ApplicationRecord
  include AASM, Syncable, Monetizable, Chartable, Enrichable, Anchorable, Reconcileable

  validates :name, :balance, :currency, presence: true

  belongs_to :family
  belongs_to :import, optional: true

  has_many :import_mappings, as: :mappable, dependent: :destroy, class_name: "Import::Mapping"
  has_many :entries, dependent: :destroy
  has_many :transactions, through: :entries, source: :entryable, source_type: "Transaction"
  has_many :valuations, through: :entries, source: :entryable, source_type: "Valuation"
  has_many :trades, through: :entries, source: :entryable, source_type: "Trade"
  has_many :holdings, dependent: :destroy
  has_many :balances, dependent: :destroy

  monetize :balance, :cash_balance

  enum :classification, { asset: "asset", liability: "liability" }, validate: { allow_nil: true }

  scope :visible, -> { where(status: [ "draft", "active" ]) }
  scope :assets, -> { where(classification: "asset") }
  scope :liabilities, -> { where(classification: "liability") }
  scope :alphabetically, -> { order(:name) }
  # Self-hosted: Plaid sme odpojili, ručné sú účty bez bankového prepojenia.
  scope :manual, -> { where(plaid_account_id: nil) }

  before_destroy :remove_linked_transfer_activity
  after_commit :sync_counterpart_accounts_after_destroy, on: :destroy

  has_one_attached :logo

  delegated_type :accountable, types: Accountable::TYPES, dependent: :destroy

  accepts_nested_attributes_for :accountable, update_only: true

  # Account state machine
  aasm column: :status, timestamps: true do
    state :active, initial: true
    state :draft
    state :disabled
    state :pending_deletion

    event :activate do
      transitions from: [ :draft, :disabled ], to: :active
    end

    event :disable do
      transitions from: [ :draft, :active ], to: :disabled
    end

    event :enable do
      transitions from: :disabled, to: :active
    end

    event :mark_for_deletion do
      transitions from: [ :draft, :active, :disabled ], to: :pending_deletion
    end
  end

  class << self
    def create_and_sync(attributes)
      attributes[:accountable_attributes] ||= {} # Ensure accountable is created, even if empty
      account = new(attributes.merge(cash_balance: attributes[:balance]))
      initial_balance = attributes.dig(:accountable_attributes, :initial_balance)&.to_d

      transaction do
        account.save!

        manager = Account::OpeningBalanceManager.new(account)
        result = manager.set_opening_balance(balance: initial_balance || account.balance)
        raise result.error if result.error
      end

      account.sync_later
      account
    end
  end

  def institution_domain
    nil
  end

  def manual?
    plaid_account_id.blank?
  end

  def destroy_later
    destroy
  end

  # Override destroy to handle error recovery for accounts
  def destroy
    super
  rescue => e
    # If destruction fails, transition back to disabled state
    # This provides a cleaner recovery path than the generic scheduled_for_deletion flag
    disable! if may_disable?
    raise e
  end

  def current_holdings
    holdings.where(currency: currency)
            .where.not(qty: 0)
            .where(
              id: holdings.select("DISTINCT ON (security_id) id")
                          .where(currency: currency)
                          .order(:security_id, date: :desc)
            )
            .order(amount: :desc)
  end

  def start_date
    first_entry_date = entries.minimum(:date) || Date.current
    first_entry_date - 1.day
  end

  def lock_saved_attributes!
    super
    accountable.lock_saved_attributes!
  end

  def first_valuation
    entries.valuations.order(:date).first
  end

  def first_valuation_amount
    first_valuation&.amount_money || balance_money
  end

  # Get short version of the subtype label
  def short_subtype_label
    accountable_class.short_subtype_label_for(subtype) || accountable_class.display_name
  end

  # Get long version of the subtype label
  def long_subtype_label
    accountable_class.long_subtype_label_for(subtype) || accountable_class.display_name
  end

  # The balance type determines which "component" of balance is being tracked.
  # This is primarily used for balance related calculations and updates.
  #
  # "Cash" = "Liquid"
  # "Non-cash" = "Illiquid"
  # "Investment" = A mix of both, including brokerage cash (liquid) and holdings (illiquid)
  def balance_type
    case accountable_type
    when "Depository", "CreditCard"
      :cash
    when "Property", "Vehicle", "OtherAsset", "Loan", "OtherLiability"
      :non_cash
    when "Investment", "Crypto"
      :investment
    else
      raise "Unknown account type: #{accountable_type}"
    end
  end

  private
    # Platby leasingu / prevody sú pár transakcií. Pri zmazaní účtu zmažeme
    # aj druhú stranu (napr. „Payment to leasing auta“ na bežnom účte).
    def remove_linked_transfer_activity
      txn_ids = entries.where(entryable_type: "Transaction").pluck(:entryable_id)
      return if txn_ids.empty?

      transfers = Transfer.where(inflow_transaction_id: txn_ids)
                          .or(Transfer.where(outflow_transaction_id: txn_ids))
      rejected = RejectedTransfer.where(inflow_transaction_id: txn_ids)
                                 .or(RejectedTransfer.where(outflow_transaction_id: txn_ids))

      related_ids = (
        transfers.pluck(:inflow_transaction_id, :outflow_transaction_id) +
        rejected.pluck(:inflow_transaction_id, :outflow_transaction_id)
      ).flatten.compact.uniq

      counterpart_ids = related_ids - txn_ids
      counterpart_entries = Entry.where(entryable_type: "Transaction", entryable_id: counterpart_ids)
      @counterpart_account_ids_for_sync = counterpart_entries.distinct.pluck(:account_id)

      transfers.delete_all
      rejected.delete_all
      counterpart_entries.find_each(&:destroy)
    end

    def sync_counterpart_accounts_after_destroy
      ids = Array(@counterpart_account_ids_for_sync).uniq
      return if ids.empty?

      Account.where(id: ids).find_each do |account|
        account.sync_now
      rescue => e
        Rails.logger.warn("[Account] counterpart sync after destroy failed: #{e.class} #{e.message}")
        account.sync_later
      end
    end
end
