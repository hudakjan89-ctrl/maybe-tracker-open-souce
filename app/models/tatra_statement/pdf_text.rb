require "open3"
require "tempfile"

# Ťahá čitateľný text z PDF. Najprv skúsi pdftotext (poppler), inak číta
# textové objekty priamo z PDF streamu, aby import fungoval aj bez poppleru.
class TatraStatement::PdfText
  def self.extract(bytes)
    binary = bytes.to_s.dup.force_encoding(Encoding::BINARY)
    return "" if binary.blank?

    from_pdftotext(binary).presence || from_streams(binary)
  end

  class << self
    private
      def from_pdftotext(binary)
        return nil unless pdftotext_available?

        Tempfile.create([ "tatra", ".pdf" ]) do |file|
          file.binmode
          file.write(binary)
          file.flush

          stdout, _stderr, status = Open3.capture3("pdftotext", "-layout", "-q", file.path, "-")
          status.success? ? stdout.to_s : nil
        end
      rescue Errno::ENOENT
        nil
      end

      def pdftotext_available?
        return @pdftotext_available if defined?(@pdftotext_available)

        _out, _err, status = Open3.capture3("pdftotext", "-v")
        @pdftotext_available = status.success?
      rescue Errno::ENOENT
        @pdftotext_available = false
      end

      def from_streams(binary)
        texts = []

        binary.scan(/\(((?:\\.|[^\\)])*)\)\s*Tj/m) do |match|
          texts << unescape_pdf_string(match[0])
        end

        binary.scan(/\[(.*?)\]\s*TJ/m) do |match|
          match[0].scan(/\(((?:\\.|[^\\)])*)\)/) do |inner|
            texts << unescape_pdf_string(inner[0])
          end
          match[0].scan(/<([0-9A-Fa-f\s]+)>/) do |hex|
            texts << decode_hex_string(hex[0])
          end
        end

        binary.scan(/<([0-9A-Fa-f\s]+)>\s*Tj/) do |hex|
          texts << decode_hex_string(hex[0])
        end

        texts.map { |t| t.to_s.gsub(/[\r\n]+/, " ").strip }.reject(&:blank?).join("\n")
      end

      def unescape_pdf_string(str)
        decoded = str.to_s.dup
        decoded.gsub!(/\\(\d{1,3})/) { $1.to_i(8).chr }
        decoded.gsub!("\\n", "\n")
        decoded.gsub!("\\r", "\r")
        decoded.gsub!("\\t", "\t")
        decoded.gsub!("\\(", "(")
        decoded.gsub!("\\)", ")")
        decoded.gsub!("\\\\", "\\")
        decoded.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: "")
      rescue
        str.to_s
      end

      def decode_hex_string(hex)
        raw = [ hex.to_s.gsub(/\s+/, "") ].pack("H*")
        if raw.bytesize >= 2 && raw.bytes[0] == 0xFE && raw.bytes[1] == 0xFF
          raw[2..].encode(Encoding::UTF_8, Encoding::UTF_16BE, invalid: :replace, undef: :replace, replace: "")
        else
          raw.encode(Encoding::UTF_8, Encoding::Windows_1252, invalid: :replace, undef: :replace, replace: "")
        end
      rescue
        ""
      end
  end
end
