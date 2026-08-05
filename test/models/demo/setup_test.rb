require "test_helper"

class Demo::SetupTest < ActiveSupport::TestCase
  setup do
    @family = families(:empty)
    @family.accounts.destroy_all
    @family.categories.destroy_all
    @family.budgets.destroy_all
  end

  test "populate creates accounts, transactions, budget and syncs" do
    Demo::Setup.new(@family).populate!(add_transactions: true)

    assert_equal 4, @family.accounts.count
    assert_operator @family.categories.count, :>=, 10
    assert_operator @family.entries.count, :>=, 50
    assert @family.accounts.exists?(name: "Hlavný účet")
    assert @family.accounts.exists?(name: "Sporenie")
    assert @family.accounts.exists?(name: "Kreditná karta")
    assert @family.accounts.exists?(name: "Investičné portfólio")
    assert_equal "EUR", @family.reload.currency
    assert @family.budgets.exists?
    assert @family.accounts.joins(:balances).exists?
  end

  test "populate is idempotent for accounts" do
    Demo::Setup.new(@family).populate!(add_transactions: true)
    account_count = @family.accounts.count

    Demo::Setup.new(@family).populate!

    assert_equal account_count, @family.accounts.count
  end
end
