module MerchantLogo
  class LogoUrl
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
          token = name.split(/[\s\-–—]+/).first
          return nil if token.blank? || token.length < 3

          "#{token}.com"
        end
    end
  end

  class Assigner
    def initialize(family:, name:)
      @family = family
      @name = name.to_s.strip
    end

    def assign_to(transaction)
      return transaction.merchant if transaction.merchant.present?
      return nil if @name.blank?

      merchant = find_or_create_merchant
      transaction.update!(merchant: merchant) if merchant
      merchant
    end

    class << self
      def assign_to_transaction!(transaction, entry_name:)
        new(family: transaction.entry.account.family, name: entry_name).assign_to(transaction)
      end
    end

    private

      def find_or_create_merchant
        existing = @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
        return existing if existing

        logo_url = LogoUrl.for(@name)
        return nil unless logo_url

        @family.merchants.create!(name: @name, logo_url: logo_url)
      rescue ActiveRecord::RecordInvalid
        @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
      end
  end
end
