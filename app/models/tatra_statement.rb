# Import pohybov z výpisu Tatra banky (CSV z Histórie pohybov, PDF alebo skopírovaný text).
module TatraStatement
  class Error < StandardError; end
  class EmptyText < Error; end
  class NoTransactions < Error; end

  def self.decode(bytes)
    raw = bytes.to_s
    return "" if raw.blank?

    utf8 = raw.dup.force_encoding(Encoding::UTF_8)
    return utf8 if utf8.valid_encoding?

    raw.force_encoding("Windows-1250").encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  rescue EncodingError, ArgumentError
    raw.to_s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
  end
end
