require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  include SyncableInterfaceTest

  def setup
    @syncable = families(:dylan_family)
  end

  test "purges leftover payments to a paid-off liability" do
    family = families(:dylan_family)
    liability = accounts(:other_liability)
    depository = accounts(:depository)

    liability.update!(name: "leasing auta")

    Transfer::Creator.new(
      family: family,
      source_account_id: depository.id,
      destination_account_id: liability.id,
      date: Date.current,
      amount: 50
    ).create

    liability.disable!
    payment_name = "Payment to leasing auta"
    assert depository.entries.exists?(name: payment_name)

    family.purge_leftover_liability_payments!

    assert_not Account.exists?(liability.id)
    assert_not depository.entries.exists?(name: payment_name)
  end

  test "default cash account prefers a checking-style name" do
    assert_equal accounts(:depository), families(:dylan_family).default_cash_account
  end

  test "resets leftover demo cash on Hlavný účet" do
    family = families(:dylan_family)
    account = family.accounts.create!(
      name: "Hlavný účet",
      balance: 7538,
      cash_balance: 7538,
      currency: "USD",
      accountable: Depository.new
    )

    family.reset_leftover_demo_cash_balances!

    assert_equal 0, account.reload.balance
  end
end
