require "csv"

class TatraStatement::Importer
  Result = Struct.new(:imported_count, :duplicate_count, :import, keyword_init: true) do
    def notice
      parts = [ "Naimportovaných #{imported_count} #{transaction_word(imported_count)} z výpisu Tatra banky." ]
      if duplicate_count.positive?
        parts << "#{duplicate_count} #{transaction_word(duplicate_count)} už v účte boli, preto sa nepridali znova."
      end
      parts.join(" ")
    end

    private
      def transaction_word(count)
        case count
        when 1 then "transakcia"
        when 2..4 then "transakcie"
        else "transakcií"
        end
      end
  end

  def initialize(family:, account:, bytes:, filename: "vypis.pdf")
    @family = family
    @account = account
    @bytes = bytes
    @filename = filename.to_s
  end

  def call
    import = nil
    parsed = parse_all
    raise TatraStatement::NoTransactions, "Vo výpise sa nenašli žiadne pohyby." if parsed.empty?

    unique, duplicates = split_duplicates(parsed)

    import = create_import!(parsed)
    created = []

    Import.transaction do
      created = insert_transactions!(import, unique)
      import.update!(status: :complete)
    end

    assign_logos!(created)
    sync_account_safely

    Result.new(imported_count: created.size, duplicate_count: duplicates.size, import: import)
  rescue TatraStatement::Error => e
    import&.update!(status: :failed, error: e.message) if import&.persisted?
    raise
  rescue => e
    import&.update!(status: :failed, error: e.message) if import&.persisted?
    Rails.logger.error("[TatraStatement::Importer] #{e.class}: #{e.message}\n#{e.backtrace.first(12).join("\n")}")
    raise TatraStatement::Error, "Výpis sa nepodarilo spracovať: #{e.message}"
  end

  private
    def parse_all
      text = extract_text
      raise TatraStatement::EmptyText, "PDF neobsahuje čitateľný text. Exportujte výpis z internet bankingu, nie naskenovaný obrázok." if text.blank?

      parser = if TatraStatement::CsvParser.handles?(text)
        TatraStatement::CsvParser.new(text)
      else
        TatraStatement::Parser.new(text)
      end

      parser.transactions
    end

    def extract_text
      if pdf?
        TatraStatement::PdfText.extract(@bytes)
      else
        decode_bytes(@bytes)
      end
    end

    def decode_bytes(bytes)
      raw = bytes.to_s
      utf8 = raw.dup.force_encoding(Encoding::UTF_8)
      return utf8 if utf8.valid_encoding?

      raw.force_encoding("Windows-1250").encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    rescue EncodingError
      raw.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end

    def pdf?
      @bytes.to_s.start_with?("%PDF") || File.extname(@filename).downcase == ".pdf"
    end

    def split_duplicates(parsed)
      existing = @account.entries.where(entryable_type: "Transaction").group(:date, :amount, :name).count
      matched = Hash.new(0)
      unique = []
      duplicates = []

      parsed.each do |txn|
        maybe_amount = maybe_signed_amount(txn.amount)
        key = [ txn.date, maybe_amount, txn.name ]
        if matched[key] < (existing[key] || 0)
          matched[key] += 1
          duplicates << txn
        else
          unique << txn
        end
      end

      [ unique, duplicates ]
    end

    # Bank: záporné = peniaze preč. Maybe: kladné = výdavok.
    def maybe_signed_amount(bank_amount)
      -bank_amount.to_d
    end

    def create_import!(parsed)
      @family.imports.create!(
        type: "TransactionImport",
        account: @account,
        date_format: "%d.%m.%Y",
        number_format: "1,234.56",
        signage_convention: "inflows_positive",
        amount_type_strategy: "signed_amount",
        status: :importing,
        raw_file_str: to_csv(parsed)
      )
    end

    def to_csv(parsed)
      CSV.generate do |csv|
        csv << %w[date amount name currency]
        parsed.each do |txn|
          csv << [ txn.date.strftime("%d.%m.%Y"), txn.amount.to_s("F"), txn.name, txn.currency ]
        end
      end
    end

    def insert_transactions!(import, unique)
      return [] if unique.empty?

      categorizer = TatraStatement::Categorizer.new(@family)
      currency = @account.currency.presence || @family.currency.presence || "EUR"

      records = unique.map do |txn|
        Transaction.new(
          category: categorizer.category_for(txn.name),
          entry: Entry.new(
            account: @account,
            date: txn.date,
            amount: maybe_signed_amount(txn.amount),
            name: txn.name,
            currency: currency,
            import: import
          )
        )
      end

      Transaction.import!(records, recursive: true)
      records
    end

    def sync_account_safely
      @account.sync_now
    rescue => e
      Rails.logger.warn("[TatraStatement] sync after import failed: #{e.class} #{e.message}")
      @account.sync_later
    end

    def assign_logos!(transactions)
      transactions.each do |transaction|
        entry_name = transaction.entry&.name
        next if entry_name.blank?

        MerchantLogo::Assigner.assign_to_transaction!(transaction, entry_name: entry_name)
      rescue => e
        Rails.logger.warn("[TatraStatement] logo skip: #{e.class} #{e.message}")
      end
    end
end
