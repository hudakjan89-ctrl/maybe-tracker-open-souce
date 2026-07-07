class Account::SyncCompleteEvent
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def broadcast
    account.broadcast_replace_to(
      account.family,
      target: "account_#{account.id}",
      partial: "accounts/account",
      locals: { account: account }
    )

    sidebar_targets.each do |(tab, mobile_flag)|
      account.broadcast_replace_to(
        account.family,
        target: account_group.dom_id(tab: tab, mobile: mobile_flag),
        partial: "accounts/accountable_group",
        locals: { account_group: account_group, open: true, all_tab: tab == :all, mobile: mobile_flag }
      )
    end

    account.family.broadcast_sync_complete
    account.broadcast_refresh
  end

  private
    def sidebar_targets
      return [] unless account_group.present?

      [
        [ account_group.classification.to_sym, false ],
        [ :all, false ],
        [ account_group.classification.to_sym, true ],
        [ :all, true ]
      ]
    end

    def account_group
      family_balance_sheet.account_groups.find do |group|
        group.accounts.any? { |a| a.id == account.id }
      end
    end

    def family_balance_sheet
      account.family.balance_sheet
    end
end
