require "test_helper"

class TatraStatement::CsvParserTest < ActiveSupport::TestCase
  setup do
    @text = file_fixture("tatra_export.csv").read
  end

  test "detects official Tatra CSV export" do
    assert TatraStatement::CsvParser.handles?(@text)
    assert_not TatraStatement::CsvParser.handles?("24.07.2026 Kaufland -69,00")
  end

  test "parses every row with Debet as outflow and Kredit as inflow" do
    txns = TatraStatement::CsvParser.new(@text).transactions

    assert_equal 10, txns.size, txns.map { |t| [ t.date, t.name, t.amount ] }.inspect

    bufet = txns.find { |t| t.name == "BUFET AGLOMERACIA" }
    assert_equal Date.new(2026, 6, 15), bufet.date
    assert_equal BigDecimal("-4.04"), bufet.amount

    mcdonalds = txns.find { |t| t.name.include?("McDonald") }
    assert_equal BigDecimal("-14.30"), mcdonalds.amount

    revolut = txns.find { |t| t.name == "Revolut" }
    assert_equal BigDecimal("-20.00"), revolut.amount

    income = txns.find { |t| t.name == "Príjem — Tatra banka" }
    assert_equal BigDecimal("173.50"), income.amount

    csob = txns.find { |t| t.name == "Platba — ČSOB" }
    assert_equal BigDecimal("-100.00"), csob.amount

    shop = txns.find { |t| t.name == "SHOPTEST.SK" }
    assert_equal BigDecimal("-50.49"), shop.amount

    refund = txns.find { |t| t.name.start_with?("Vrátenie") }
    assert_equal "Vrátenie — FILTREAOLEJE.SK", refund.name
    assert_equal BigDecimal("12.67"), refund.amount

    from_revolut = txns.find { |t| t.name == "Odoslane z Revolutu" }
    assert_equal BigDecimal("5.77"), from_revolut.amount

    slsp = txns.find { |t| t.name == "Príjem — Slovenská sporiteľňa" }
    assert_equal BigDecimal("30.00"), slsp.amount

    fresh = txns.find { |t| t.name == "SUPERMARKET FRESH" }
    assert_equal Date.new(2026, 9, 25), fresh.date
    assert_equal BigDecimal("-2.44"), fresh.amount
  end

  test "does not keep card PAN or cardholder in the merchant name" do
    names = TatraStatement::CsvParser.new(@text).transactions.map(&:name).join(" ")

    assert_no_match(/\d{6}\*{2,}/, names)
    assert_no_match(/HUD[AÁ]K/i, names)
    assert_no_match(/\bJAN\b/, names)
  end
end
