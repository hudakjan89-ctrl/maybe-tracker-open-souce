require "test_helper"

class TatraStatement::ParserTest < ActiveSupport::TestCase
  SAMPLE = <<~TEXT
    Tatra banka, a.s.
    Výpis z účtu č. SK12 1100 0000 0029 1234 5678
    Obdobie: 01.08.2026 - 31.08.2026

    Dátum transakcie Dátum zaúčtovania Popis Suma Zostatok
    01.08.2026 Počiatočný zostatok 12.345,67
    03.08.2026 03.08.2026 Úrok zo sporenia 157,00 12.502,67
    03.08.2026 03.08.2026 Nájom - Bývanie -610,00 11.892,67
    06.08.2026 06.08.2026 Payment to leasing auta -4 800,00 7.092,67
    06.08.2026 06.08.2026 Payment to leasing auta -200,00 6.892,67
    24.07.2026 24.07.2026 Kaufland -69,00 6.823,67
    24.07.2026 24.07.2026 DM drogéria -35,00 6.788,67
    26.07.2026 26.07.2026 Spotify -6,00 6.782,67
    02.08.2026 02.08.2026 Výplata - Plat 2.900,00 9.682,67
    31.08.2026 Konečný zostatok 9.682,67
  TEXT

  test "parses every movement and skips only opening/closing balances" do
    txns = TatraStatement::Parser.new(SAMPLE).transactions

    assert_equal 8, txns.size, txns.map { |t| [ t.date, t.name, t.amount ] }.inspect

    by_name = txns.index_by(&:name)
    assert_equal BigDecimal("157.00"), by_name.fetch("Úrok zo sporenia").amount
    assert_equal BigDecimal("-610.00"), txns.find { |t| t.name.include?("Nájom") }.amount
    assert_equal BigDecimal("-4800.00"), txns.find { |t| t.name.include?("leasing") && t.amount.abs > 1000 }.amount
    assert_equal BigDecimal("-200.00"), txns.find { |t| t.name.include?("leasing") && t.amount.abs < 1000 }.amount
    assert_equal BigDecimal("-69.00"), txns.find { |t| t.name.include?("Kaufland") }.amount
    assert_equal BigDecimal("-35.00"), txns.find { |t| t.name.include?("DM") }.amount
    assert_equal BigDecimal("-6.00"), txns.find { |t| t.name.include?("Spotify") }.amount
    assert_equal BigDecimal("2900.00"), txns.find { |t| t.name.include?("Výplata") }.amount
  end

  test "merges continuation lines into the merchant name" do
    text = <<~TEXT
      08.08.2026 PLATBA KARTOU -12,34 1.000,00
               KAUFLAND BA-PETRZALKA
      09.08.2026 LIDL BA -23,50 976,50
    TEXT

    txns = TatraStatement::Parser.new(text).transactions
    assert_equal 2, txns.size
    assert_match(/KAUFLAND/, txns.first.name)
    assert_equal BigDecimal("-12.34"), txns.first.amount
    assert_match(/LIDL/, txns.second.name)
  end

  test "extracts text from a simple PDF stream" do
    pdf = minimal_pdf("24.07.2026 Kaufland -69,00")
    text = TatraStatement::PdfText.extract(pdf)
    assert_match(/Kaufland/, text)
    txns = TatraStatement::Parser.new(text).transactions
    assert_equal 1, txns.size
    assert_equal BigDecimal("-69.00"), txns.first.amount
  end

  private
    def minimal_pdf(text)
      escaped = text.gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
      stream = "BT /F1 12 Tf 50 700 Td (#{escaped}) Tj ET"
      <<~PDF
        %PDF-1.4
        1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
        2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
        3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
        4 0 obj<</Length #{stream.bytesize}>>stream
        #{stream}
        endstream
        endobj
        5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
        trailer<</Root 1 0 R>>
        %%EOF
      PDF
    end
end
