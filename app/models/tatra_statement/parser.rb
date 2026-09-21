# Rozoberie text výpisu Tatra banky na jednotlivé pohyby.
# Vynechá len zostatkové / hlavičkové riadky — každú skutočnú transakciu nechá.
class TatraStatement::Parser
  Transaction = Struct.new(:date, :amount, :name, :currency, :raw, keyword_init: true)

  DATE = /(\d{1,2}[.\-\/]\d{1,2}[.\-\/]\d{2,4})/
  AMOUNT = /
    (?<sign_before>[-+])?
    \s*
    (?<number>
      \d{1,3}(?:[.\s]\d{3})+,\d{2}
      |
      \d+,\d{2}
    )
    \s*
    (?<sign_after>[-+])?
    (?:\s*(?:EUR|€))?
  /x
  SKIP_NAME = /
    \A\s*(
      po[cč]iato[cč]n[yý]\s+zostatok
      | za[cč]iato[cč]n[yý]\s+zostatok
      | kone[cč]n[yý]\s+zostatok
      | zostatok\s+na\s+[uú][cč]te
      | dostupn[yý]\s+zostatok
      | v[yý]pis\s+z\s+[uú][cč]tu
      | strana\s+\d+
      | iban\b
      | swift\b
    )
  /ix

  def initialize(text)
    @text = text.to_s.tr("\u00A0", " ")
  end

  def transactions
    rows = parse_lines
    rows = scan_globally if rows.empty?
    rows.reject { |txn| skip?(txn) }
  end

  private
    def parse_lines
      lines = @text.lines.map { |line| line.gsub(/\s+/, " ").strip }.reject(&:blank?)
      results = []
      i = 0

      while i < lines.length
        line = lines[i]
        unless date_in?(line)
          i += 1
          next
        end

        chunk = line.dup
        j = i + 1
        unless amount_in?(line)
          while j < lines.length && j <= i + 4 && !date_in?(lines[j])
            chunk = "#{chunk} #{lines[j]}"
            j += 1
            break if amount_in?(chunk)
          end
        else
          while j < lines.length && j <= i + 3 && !date_in?(lines[j]) && !amount_in?(lines[j])
            chunk = "#{chunk} #{lines[j]}"
            j += 1
          end
        end

        parsed = parse_chunk(chunk)
        results.concat(Array(parsed).compact)
        i = [ j, i + 1 ].max
      end

      results
    end

    def scan_globally
      results = []
      used_amount_ranges = []
      offset = 0

      while (date_match = DATE.match(@text, offset))
        date_str = date_match[0]
        after_index = date_match.end(0)
        after = @text[after_index..]
        amount_match = after&.match(AMOUNT)

        unless amount_match
          offset = after_index
          next
        end

        amount_begin = after_index + amount_match.begin(0)
        amount_end = after_index + amount_match.end(0)

        if used_amount_ranges.any? { |from, to| amount_begin < to && amount_end > from }
          offset = after_index
          next
        end

        used_amount_ranges << [ amount_begin, amount_end ]
        name = after[0...amount_match.begin(0)].to_s
        results << build_transaction(date_str, amount_match, name, "#{date_str} #{amount_match[0]}")
        offset = amount_end
      end

      results
    end

    def parse_chunk(chunk)
      dates = chunk.scan(DATE).flatten
      return [] if dates.empty?

      amounts = []
      chunk.scan(AMOUNT) { amounts << Regexp.last_match }

      return [] if amounts.empty?

      txn_amount_match = pick_transaction_amount(amounts)
      return [] unless txn_amount_match

      date_str = dates.first
      name = chunk.dup
      dates.each { |d| name = name.sub(d, " ") }
      name = name.sub(txn_amount_match[0], " ")
      amounts.each { |m| name = name.sub(m[0], " ") }

      [ build_transaction(date_str, txn_amount_match, name, chunk) ]
    end

    def pick_transaction_amount(matches)
      return matches.first if matches.size == 1

      # Posledná suma na riadku býva bežný zostatok — berieme predchádzajúcu.
      candidates = matches[0..-2]
      signed = candidates.find { |m| m[:sign_before].present? || m[:sign_after].present? }
      signed || candidates.first || matches.first
    end

    def build_transaction(date_str, amount_match, name, raw)
      date = parse_date(date_str)
      amount = parse_amount(amount_match)
      return nil unless date && amount

      Transaction.new(
        date: date,
        amount: amount,
        name: clean_name(name),
        currency: "EUR",
        raw: raw.to_s.strip
      )
    end

    def parse_date(str)
      parts = str.to_s.split(/[.\-\/]/).map(&:to_i)
      return nil unless parts.size == 3

      day, month, year = parts
      year += 2000 if year < 100
      Date.new(year, month, day)
    rescue ArgumentError, Date::Error
      nil
    end

    def parse_amount(match)
      number = match[:number].to_s
      negative = match[:sign_before] == "-" || match[:sign_after] == "-"

      normalized = if number.include?(",")
        number.gsub(/[.\s]/, "").sub(",", ".")
      else
        number.gsub(/\s/, "").delete(",")
      end

      value = BigDecimal(normalized)
      negative ? -value : value
    rescue ArgumentError
      nil
    end

    def clean_name(name)
      cleaned = name.to_s
                    .gsub(/\b(EUR|€)\b/i, " ")
                    .gsub(/\b(debet|kredit|suma|dátum|datum|zaúčtovania|zauctovania|transakcie)\b/i, " ")
                    .gsub(/[|;]+/, " ")
                    .gsub(/\s+/, " ")
                    .strip
                    .truncate(140)

      cleaned.presence || "Transakcia Tatra banka"
    end

    def skip?(txn)
      return true if txn.nil? || txn.date.nil? || txn.amount.nil?
      return true if txn.date > Date.current + 14.days
      return true if txn.date < Entry.min_supported_date
      return true if txn.name == "Transakcia Tatra banka" && txn.raw.to_s.match?(/zostatok/i)
      return true if SKIP_NAME.match?(txn.name)

      false
    end

    def date_in?(line)
      DATE.match?(line.to_s)
    end

    def amount_in?(line)
      AMOUNT.match?(line.to_s)
    end
end
