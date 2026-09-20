module Merchant
  class LogoUrl
    # Doména pre Clearbit logo API (bez API kľúča, funguje pre známe značky)
    CLEARBIT = "https://logo.clearbit.com/%<domain>s"

    KNOWN = {
      "spotify" => "spotify.com",
      "netflix" => "netflix.com",
      "kaufland" => "kaufland.sk",
      "tesco" => "tesco.sk",
      "lidl" => "lidl.sk",
      "billa" => "billa.sk",
      "dm drogéria" => "dm.sk",
      "dm" => "dm.sk",
      "ikea" => "ikea.com",
      "starbucks" => "starbucks.com",
      "vodafone" => "vodafone.sk",
      "bolt" => "bolt.eu",
      "revolut" => "revolut.com",
      "apple" => "apple.com",
      "google" => "google.com",
      "amazon" => "amazon.com"
    }.freeze

    EMOJI = {
      /spotify/i => "🎵",
      /netflix/i => "📺",
      /kaufland|tesco|lidl|billa|potraviny/i => "🛒",
      /dm/i => "💄",
      /starbucks|reštaur/i => "☕",
      /bolt|benzín|doprava|leasing/i => "🚗",
      /výplata|plat|príjem|úrok/i => "💰",
      /nájom|bývanie|hypoték/i => "🏠",
      /lekáreň|zdravie/i => "💊",
      /kino|zábava/i => "🎬",
      /online nákup/i => "🛍️",
      /payment|platba|splátka/i => "💳"
    }.freeze

    class << self
      def for(name)
        domain = domain_for(name)
        format(CLEARBIT, domain: domain) if domain
      end

      def emoji_for(name)
        EMOJI.each { |pattern, emoji| return emoji if name.to_s.match?(pattern) }
        nil
      end

      def domain_for(name)
        normalized = normalize(name)
        return nil if normalized.blank?

        KNOWN[normalized] || guess_domain(normalized)
      end

      private

        def normalize(name)
          name.to_s.strip.downcase
        end

        def guess_domain(name)
          # "Spotify Premium" -> spotify.com
          token = name.split(/[\s\-–—]+/).first
          return nil if token.blank? || token.length < 3

          "#{token}.com"
        end
    end
  end
end
