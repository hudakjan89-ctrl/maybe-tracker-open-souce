module Liability
  class PaymentRecorder
    Result = Struct.new(:success?, :transfer, :error, keyword_init: true)

    def initialize(family:, liability:, amount:, date:, source_account_id: nil)
      @family = family
      @liability = liability
      @amount = amount.to_d
      @date = date
      @source_account_id = source_account_id
    end

    def record
      source = source_account
      return Result.new(success?: false, error: "Vyberte účet, z ktorého platíte.") unless source
      return Result.new(success?: false, error: "Suma musí byť väčšia ako nula.") unless @amount.positive?

      transfer = Transfer::Creator.new(
        family: @family,
        source_account_id: source.id,
        destination_account_id: @liability.id,
        date: @date,
        amount: @amount,
        sync_immediately: true
      ).create

      if transfer.persisted?
        Result.new(success?: true, transfer: transfer)
      else
        Result.new(success?: false, error: transfer.errors.full_messages.to_sentence.presence || "Platbu sa nepodarilo uložiť.")
      end
    end

    private

      def source_account
        if @source_account_id.present?
          @family.accounts.visible.find_by(id: @source_account_id)
        else
          @family.accounts.visible.where(accountable_type: "Depository").alphabetically.first
        end
      end
  end
end
