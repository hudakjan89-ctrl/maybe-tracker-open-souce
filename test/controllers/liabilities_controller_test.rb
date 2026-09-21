require "test_helper"

class LiabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @liability = accounts(:other_liability)
    @depository = accounts(:depository)
  end

  test "destroy removes liability and counterpart payments" do
    transfer = Transfer::Creator.new(
      family: @user.family,
      source_account_id: @depository.id,
      destination_account_id: @liability.id,
      date: Date.current,
      amount: 50
    ).create

    assert transfer.persisted?
    payment_name = "Payment to #{@liability.name}"
    assert @depository.entries.exists?(name: payment_name)

    delete liability_url(@liability)

    assert_redirected_to root_path
    assert_not Account.exists?(@liability.id)
    assert_not Transfer.exists?(transfer.id)
    assert_not @depository.entries.exists?(name: payment_name)
    assert_match(/zmazané/, flash[:notice])
  end
end
