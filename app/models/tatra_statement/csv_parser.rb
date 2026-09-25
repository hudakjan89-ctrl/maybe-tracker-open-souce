require "csv"
require "bigdecimal"
require "date"

# Oficiálny CSV export z internet bankingu Tatra banky
# (História pohybov → Exportovať).
#
# Suma je vždy kladná; smer určuje stĺpec Typ (Debet = preč, Kredit = dnu).
class TatraStatement::CsvParser
  Transaction = Struct.new(:date, :amount, :name, :currency, :raw, keyword_init: true)

  BANKS = {
    "0200" => "VÚB",
    "0720" => "NBS",
    "0900" => "Slovenská sporiteľňa",
    "1100" => "Tatra banka",
    "1111" => "UniCredit",
    "3100" => "Tatra banka",
    "5600" => "Prima banka",
    "5900" => "Prima banka",
    "6500" => "Poštová banka",
    "7500" => "ČSOB",
    "8120" => "Prima banka",
    "8130" => "Citibank",
    "8170" => "ČSOB",
    "8180" => "Wüstenrot",
    "8320" => "J&T Banka",
    "8330" => "Fio banka",
    "8360" => "mBank",
    "8370" => "UniCredit",
    "8420" => "Raiffeisen"
  }.freeze

  HEADER_ALIASES = {
    "dátum spracovania" => :processed_on,
    "datum spracovania" => :processed_on,
    "dátum zúčtovania" => :booked_on,
    "datum zuctovania" => :booked_on,
    "suma" => :amount,
    "mena" => :currency,
    "typ" => :kind,
    "predčíslie" => :prefix,
    "predcislie" => :prefix,
    "číslo účtu" => :account_number,
    "cislo uctu" => :account_number,
    "kód banky" => :bank_code,
    "kod banky" => :bank_code,
    "iban" => :iban,
    "informácia pre príjemcu" => :info,
    "informacia pre prijemcu" => :info,
    "popis" => :description
  }.freeze

  CARD_MASK = /\d{6}\*{2,}\d{2,6}/
  TIMESTAMP = /\b(\d{8})(?:\s+(\d{2}:\d{2}:\d{2}))?\s+(?:[\d.]+\s*EUR\s+)?(.+)\z/i

  def self.handles?(text)
    head = text.to_s.sub(/\A\uFEFF/, "").lines.find { |line| line.include?(",") || line.include?(";") }.to_s
    head.match?(/d[aá]tum\s+spracovania/i) && head.match?(/\bsuma\b/i) && head.match?(/\btyp\b/i)
  end

  def initialize(text)
    @text = text.to_s.sub(/\A\uFEFF/, "")
  end

  def transactions
    rows.filter_map { |row| build_transaction(row) }
  end

  private
    def rows
      CSV.parse(@text, col_sep: delimiter, headers: true, skip_blanks: true)
    rescue CSV::MalformedCSVError
      CSV.parse(@text, col_sep: delimiter, headers: true, skip_blanks: true, liberal_parsing: true)
    end

    def delimiter
      first = @text.lines.find { |line| line.match?(/suma/i) } || @text.lines.first.to_s
      first.count(";") > first.count(",") ? ";" : ","
    end

    def build_transaction(row)
      fields = mapped(row)
      date = parse_date(fields[:booked_on].presence || fields[:processed_on])
      amount = parse_amount(fields[:amount])
      return nil unless date && amount

      amount = -amount if debit?(fields[:kind])
      name = name_for(fields)
      return nil if name.blank?

      Transaction.new(
        date: date,
        amount: amount,
        name: name,
        currency: (fields[:currency].presence || "EUR").to_s.upcase,
        raw: row.to_h.values.join(" ")
      )
    end

    def mapped(row)
      result = {}
      row.headers.each do |header|
        key = HEADER_ALIASES[normalize_header(header)]
        result[key] = row[header].to_s.strip if key
      end
      result
    end

    def normalize_header(header)
      header.to_s.sub(/\A\uFEFF/, "").strip.downcase
    end

    def debit?(kind)
      kind.to_s.match?(/\Adebet/i)
    end

    def refund?(description)
      description.to_s.match?(/n[aá]vrat/i)
    end

    def name_for(fields)
      info = fields[:info].to_s.strip
      description = fields[:description].to_s.strip

      if card_info?(info)
        merchant = merchant_from_card_info(info) || polish_name(info)
        return refund?(description) ? "Vrátenie — #{merchant}" : merchant
      end

      return polish_name(info) if info.present?

      bank = BANKS[bank_code_for(fields)]
      if bank
        return debit?(fields[:kind]) ? "Platba — #{bank}" : "Príjem — #{bank}"
      end

      polish_name(description).presence || (debit?(fields[:kind]) ? "Odchádzajúca platba" : "Prichádzajúca platba")
    end

    def card_info?(info)
      CARD_MASK.match?(info.to_s)
    end

    def merchant_from_card_info(info)
      stripped = info.to_s.sub(/\A#{CARD_MASK}\s+/o, "")
      match = stripped.match(TIMESTAMP)
      return polish_name(match[3]) if match

      euro = stripped.match(/[\d.]+\s*EUR\s+(.+)\z/i)
      polish_name(euro[1]) if euro
    end

    def bank_code_for(fields)
      code = fields[:bank_code].to_s.gsub(/\s+/, "")
      code = code.rjust(4, "0") if code.match?(/\A\d{1,4}\z/)
      return code if BANKS.key?(code)

      iban = fields[:iban].to_s.gsub(/\s+/, "")
      iban_code = iban[/\ASK\d{2}(\d{4})/, 1]
      return iban_code if iban_code

      fields[:description].to_s[/\APlatba\s+(\d{4})\//, 1]
    end

    def polish_name(name)
      cleaned = name.to_s.strip
      cleaned = cleaned.sub(%r{\Ahttps?://}i, "")
      cleaned = cleaned.sub(%r{/\z}, "")
      cleaned = cleaned.gsub(/\*{2,}\d+\*?/, "")
      cleaned = cleaned.tr("*", " ")
      cleaned = cleaned.gsub(/\s+/, " ").strip
      cleaned = cleaned.sub(/\A(GOPAY|GPAY|NYX)\s+/i, "")

      parts = cleaned.split
      if parts.size >= 2 && parts[0].casecmp(parts[1]).zero?
        parts.shift
        cleaned = parts.join(" ")
      end

      cleaned = cleaned.length > 140 ? cleaned[0, 140] : cleaned
      cleaned
    end

    def parse_date(value)
      parts = value.to_s.split(/[.\-\/]/).map(&:to_i)
      return nil unless parts.size == 3

      day, month, year = parts
      year += 2000 if year < 100
      Date.new(year, month, day)
    rescue ArgumentError, Date::Error
      nil
    end

    def parse_amount(value)
      number = value.to_s.strip.gsub(/\s/, "")
      return nil if number.blank?

      normalized = if number.include?(",")
        number.gsub(".", "").sub(",", ".")
      else
        number
      end

      BigDecimal(normalized)
    rescue ArgumentError
      nil
    end
end
