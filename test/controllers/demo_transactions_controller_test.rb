require "test_helper"

class DemoTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:empty)
    sign_in @user
    @user.family.accounts.destroy_all
    @user.family.categories.destroy_all
  end

  test "create populates demo data and redirects" do
    assert_difference -> { @user.family.accounts.count }, 4 do
      post demo_transactions_path
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end
end
