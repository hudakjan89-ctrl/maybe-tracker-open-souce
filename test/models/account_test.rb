require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include SyncableInterfaceTest, EntriesTestHelper

  setup do
    @account = @syncable = accounts(:depository)
    @family = families(:dylan_family)
  end

  test "can destroy" do
    assert_difference "Account.count", -1 do
      @account.destroy
    end
  end

  test "is manual when not linked to a bank provider" do
    assert @account.manual?
    assert_includes Account.manual, @account
  end

  test "destroying a liability also removes counterpart payment entries" do
    depository = accounts(:depository)
    credit_card = accounts(:credit_card)

    assert Transfer.exists?(transfers(:one).id)
    assert depository.entries.exists?(name: "Payment to credit card account")
    assert credit_card.entries.exists?(name: "Payment received from checking account")

    assert_difference "Account.count", -1 do
      credit_card.destroy
    end

    assert_not Transfer.exists?(transfers(:one).id)
    assert_not depository.entries.exists?(name: "Payment to credit card account")
    assert_not Entry.exists?(name: "Payment received from checking account")
  end

  test "gets short/long subtype label" do
    account = @family.accounts.create!(
      name: "Test Investment",
      balance: 1000,
      currency: "USD",
      subtype: "hsa",
      accountable: Investment.new
    )

    assert_equal "HSA", account.short_subtype_label
    assert_equal "Health Savings Account", account.long_subtype_label

    # Test with nil subtype
    account.update!(subtype: nil)
    assert_equal "Investments", account.short_subtype_label
    assert_equal "Investments", account.long_subtype_label
  end
end
