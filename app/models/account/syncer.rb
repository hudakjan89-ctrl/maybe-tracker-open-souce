class Account::Syncer
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def perform_sync(_sync)
    Rails.logger.info("Processing balances (forward) for account #{account.id}")
    Balance::Materializer.new(account, strategy: :forward).materialize_balances
  end

  def perform_post_sync
    account.family.auto_match_transfers!
  end
end
