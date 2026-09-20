require "test_helper"

class Valuation::NameTest < ActiveSupport::TestCase
  # Opening anchor tests
  test "generates opening anchor name for Property" do
    name = Valuation::Name.new("opening_anchor", "Property")
    assert_equal "Pôvodná kúpna cena", name.to_s
  end

  test "generates opening anchor name for Loan" do
    name = Valuation::Name.new("opening_anchor", "Loan")
    assert_equal "Pôvodná istina", name.to_s
  end

  test "generates opening anchor name for Investment" do
    name = Valuation::Name.new("opening_anchor", "Investment")
    assert_equal "Počiatočná hodnota účtu", name.to_s
  end

  test "generates opening anchor name for Vehicle" do
    name = Valuation::Name.new("opening_anchor", "Vehicle")
    assert_equal "Pôvodná kúpna cena", name.to_s
  end

  test "generates opening anchor name for Crypto" do
    name = Valuation::Name.new("opening_anchor", "Crypto")
    assert_equal "Počiatočná hodnota účtu", name.to_s
  end

  test "generates opening anchor name for OtherAsset" do
    name = Valuation::Name.new("opening_anchor", "OtherAsset")
    assert_equal "Počiatočná hodnota účtu", name.to_s
  end

  test "generates opening anchor name for other account types" do
    name = Valuation::Name.new("opening_anchor", "Depository")
    assert_equal "Počiatočný zostatok", name.to_s
  end

  # Current anchor tests
  test "generates current anchor name for Property" do
    name = Valuation::Name.new("current_anchor", "Property")
    assert_equal "Aktuálna trhová hodnota", name.to_s
  end

  test "generates current anchor name for Loan" do
    name = Valuation::Name.new("current_anchor", "Loan")
    assert_equal "Aktuálny zostatok úveru", name.to_s
  end

  test "generates current anchor name for Investment" do
    name = Valuation::Name.new("current_anchor", "Investment")
    assert_equal "Aktuálna hodnota účtu", name.to_s
  end

  test "generates current anchor name for Vehicle" do
    name = Valuation::Name.new("current_anchor", "Vehicle")
    assert_equal "Aktuálna trhová hodnota", name.to_s
  end

  test "generates current anchor name for Crypto" do
    name = Valuation::Name.new("current_anchor", "Crypto")
    assert_equal "Aktuálna hodnota účtu", name.to_s
  end

  test "generates current anchor name for OtherAsset" do
    name = Valuation::Name.new("current_anchor", "OtherAsset")
    assert_equal "Aktuálna hodnota účtu", name.to_s
  end

  test "generates current anchor name for other account types" do
    name = Valuation::Name.new("current_anchor", "Depository")
    assert_equal "Aktuálny zostatok", name.to_s
  end

  # Reconciliation tests
  test "generates recon name for Property" do
    name = Valuation::Name.new("reconciliation", "Property")
    assert_equal "Manuálna úprava hodnoty", name.to_s
  end

  test "generates recon name for Investment" do
    name = Valuation::Name.new("reconciliation", "Investment")
    assert_equal "Manuálna úprava hodnoty", name.to_s
  end

  test "generates recon name for Vehicle" do
    name = Valuation::Name.new("reconciliation", "Vehicle")
    assert_equal "Manuálna úprava hodnoty", name.to_s
  end

  test "generates recon name for Crypto" do
    name = Valuation::Name.new("reconciliation", "Crypto")
    assert_equal "Manuálna úprava hodnoty", name.to_s
  end

  test "generates recon name for OtherAsset" do
    name = Valuation::Name.new("reconciliation", "OtherAsset")
    assert_equal "Manuálna úprava hodnoty", name.to_s
  end

  test "generates recon name for Loan" do
    name = Valuation::Name.new("reconciliation", "Loan")
    assert_equal "Manuálna úprava istiny", name.to_s
  end

  test "generates recon name for other account types" do
    name = Valuation::Name.new("reconciliation", "Depository")
    assert_equal "Manuálna úprava zostatku", name.to_s
  end
end
