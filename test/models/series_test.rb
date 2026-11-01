require "test_helper"

class SeriesTest < ActiveSupport::TestCase
  test "trend is nil when the series has no values" do
    series = Series.new(
      start_date: Date.current,
      end_date: Date.current,
      interval: "1 day",
      values: []
    )

    assert_nil series.trend
  end

  test "trend compares the first and last value" do
    series = Series.new(
      start_date: Date.current,
      end_date: Date.current,
      interval: "1 day",
      values: [
        Series::Value.new(date: Date.current, date_formatted: "today", value: 10, trend: nil)
      ]
    )

    assert_equal "up", series.trend.direction
    assert_equal 10, series.trend.value
  end
end
