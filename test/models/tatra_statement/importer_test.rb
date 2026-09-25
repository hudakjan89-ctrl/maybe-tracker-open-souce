require "test_helper"

class TatraStatement::ImporterTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @account = accounts(:depository)
    Category.where(family: @family).bootstrap!
  end

  test "imports every parsed transaction onto the account" do
    text = <<~TEXT
      24.07.2026 Kaufland -69,00
      24.07.2026 DM drogéria -35,00
      26.07.2026 Spotify -6,00
      02.08.2026 Výplata - Plat 2.900,00
    TEXT

    result = nil
    assert_difference -> { @account.entries.transactions.count }, 4 do
      result = TatraStatement::Importer.new(
        family: @family,
        account: @account,
        bytes: text,
        filename: "vypis.txt"
      ).call
    end

    assert_equal 4, result.imported_count
    assert_equal 0, result.duplicate_count

    kaufland = @account.entries.find_by("name LIKE ?", "%Kaufland%")
    assert_equal Date.new(2026, 7, 24), kaufland.date
    assert_equal BigDecimal("69.00"), kaufland.amount

    salary = @account.entries.find_by("name LIKE ?", "%Výplata%")
    assert_equal BigDecimal("-2900.00"), salary.amount
  end

  test "does not drop a second identical movement from the same statement" do
    text = <<~TEXT
      24.07.2026 Kaufland -69,00
      24.07.2026 Kaufland -69,00
    TEXT

    result = TatraStatement::Importer.new(
      family: @family,
      account: @account,
      bytes: text,
      filename: "vypis.txt"
    ).call

    assert_equal 2, result.imported_count
    assert_equal 2, @account.entries.where(name: "Kaufland", date: Date.new(2026, 7, 24)).count
  end

  test "skips rows already present from a previous import" do
    text = <<~TEXT
      24.07.2026 Kaufland -69,00
      26.07.2026 Spotify -6,00
    TEXT

    TatraStatement::Importer.new(family: @family, account: @account, bytes: text, filename: "vypis.txt").call

    result = nil
    assert_no_difference -> { @account.entries.transactions.count } do
      result = TatraStatement::Importer.new(family: @family, account: @account, bytes: text, filename: "vypis.txt").call
    end

    assert_equal 0, result.imported_count
    assert_equal 2, result.duplicate_count
  end

  test "imports official Tatra CSV export with card merchants and bank transfers" do
    csv = file_fixture("tatra_export.csv").read

    result = TatraStatement::Importer.new(
      family: @family,
      account: @account,
      bytes: csv,
      filename: "document.csv"
    ).call

    assert_equal 10, result.imported_count
    assert_equal 0, result.duplicate_count

    bufet = @account.entries.find_by(name: "BUFET AGLOMERACIA")
    assert_equal Date.new(2026, 6, 15), bufet.date
    assert_equal BigDecimal("4.04"), bufet.amount

    income = @account.entries.find_by(name: "Príjem — Tatra banka")
    assert_equal BigDecimal("-173.50"), income.amount
  end
end
