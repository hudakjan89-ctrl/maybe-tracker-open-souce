module Merchant
  class Assigner
    def initialize(family:, name:)
      @family = family
      @name = name.to_s.strip
    end

    def assign_to(transaction)
      return transaction.merchant if transaction.merchant.present?
      return nil if @name.blank?

      merchant = find_or_create_merchant
      transaction.update!(merchant: merchant) if merchant
      merchant
    end

    class << self
      def assign_to_transaction!(transaction, entry_name:)
        new(family: transaction.entry.account.family, name: entry_name).assign_to(transaction)
      end
    end

    private

      def find_or_create_merchant
        existing = @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
        return existing if existing

        logo_url = LogoUrl.for(@name)
        return nil unless logo_url

        @family.merchants.create!(name: @name, logo_url: logo_url)
      rescue ActiveRecord::RecordInvalid
        @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
      end
  end
end
