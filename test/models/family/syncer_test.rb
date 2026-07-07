require "test_helper"

class Family::SyncerTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
  end

  test "syncs all accounts" do
    family_sync = syncs(:family)
    accounts_count = @family.accounts.count

    syncer = Family::Syncer.new(@family)

    Account.any_instance
           .expects(:sync_later)
           .with(parent_sync: family_sync, window_start_date: nil, window_end_date: nil)
           .times(accounts_count)

    syncer.perform_sync(family_sync)
  end
end
