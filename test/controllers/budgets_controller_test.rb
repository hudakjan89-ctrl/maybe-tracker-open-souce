require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "index redirects to current month budget" do
    get budgets_path
    assert_redirected_to budget_path(Budget.date_to_param(Date.current))
    follow_redirect!
    assert_response :success
  end

  test "show accepts legacy month params" do
    get budget_path("sep-2026")
    assert_response :success
  end
end
