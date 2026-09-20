# Merchant is an ActiveRecord class. Do not add app/models/merchant/*.rb —
# Zeitwerk would treat Merchant as a module and boot would fail in production.
class Merchant < ApplicationRecord
  TYPES = %w[FamilyMerchant ProviderMerchant].freeze

  has_many :transactions, dependent: :nullify

  validates :name, presence: true
  validates :type, inclusion: { in: TYPES }

  scope :alphabetically, -> { order(:name) }
end
