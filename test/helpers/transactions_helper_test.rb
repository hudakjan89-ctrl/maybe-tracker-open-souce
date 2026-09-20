require "test_helper"

class TransactionsHelperTest < ActionView::TestCase
  test "detects all period without dates" do
    assert_equal "all", transaction_period_key({})
  end

  test "detects last 30 days period" do
    period = Period.last_30_days

    assert_equal "last_30_days", transaction_period_key(
      "start_date" => period.start_date.to_s,
      "end_date" => period.end_date.to_s
    )
  end

  test "detects custom period" do
    assert_equal "custom", transaction_period_key(
      start_date: 10.days.ago.to_date,
      end_date: Date.current
    )
  end

  test "all period url drops dates and keeps other filters" do
    url = transaction_period_url("all", filters: { "search" => "spotify", "start_date" => "2026-01-01" })

    assert_includes url, "spotify"
    assert_not_includes url, "start_date"
  end

  test "preset period url sets start and end dates" do
    url = transaction_period_url("last_7_days", filters: { "search" => "spotify" })
    period = Period.last_7_days

    assert_includes url, "spotify"
    assert_includes url, period.start_date.to_s
    assert_includes url, period.end_date.to_s
  end
end
