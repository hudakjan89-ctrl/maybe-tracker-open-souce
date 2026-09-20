# Priraďuje logá a emoji k transakciám podľa ich názvu.
#
# Logá sa načítavajú priamo z Google favicon služby, takže nezaberajú
# žiadne miesto na serveri — prehliadač si ich stiahne sám a nakešuje.
#
# Logo sa použije LEN pre značky v zozname BRANDS. Pre neznáme názvy by
# Google vrátil generickú ikonu zemegule, preto tam radšej ukážeme emoji.
module MerchantLogo
  DUCKDUCKGO_URL = "https://icons.duckduckgo.com/ip3/%<domain>s.ico"
  GOOGLE_URL = "https://www.google.com/s2/favicons?domain=%<domain>s&sz=128"

  # Kľúč = ako sa značka objaví v názve transakcie (bez diakritiky, malé písmená)
  BRANDS = {
    # Potraviny a obchody
    "kaufland" => "kaufland.sk",
    "tesco" => "tesco.sk",
    "lidl" => "lidl.sk",
    "billa" => "billa.sk",
    "coop jednota" => "coop.sk",
    "jednota" => "coop.sk",
    "terno" => "terno.sk",
    "metro" => "metro.sk",
    "yeme" => "yeme.sk",

    # Drogéria a zdravie
    "dm drogeria" => "dm.sk",
    "dm" => "dm.sk",
    "teta" => "tetadrogerie.sk",
    "rossmann" => "rossmann.sk",
    "dr max" => "drmax.sk",
    "drmax" => "drmax.sk",
    "benu" => "benu.sk",

    # Nábytok a domácnosť
    "ikea" => "ikea.com",
    "jysk" => "jysk.sk",
    "obi" => "obi.sk",
    "hornbach" => "hornbach.sk",
    "mountfield" => "mountfield.sk",

    # Elektro a online
    "alza" => "alza.sk",
    "mall" => "mall.sk",
    "nay" => "nay.sk",
    "datart" => "datart.sk",
    "amazon" => "amazon.com",
    "aliexpress" => "aliexpress.com",
    "ebay" => "ebay.com",
    "temu" => "temu.com",
    "zalando" => "zalando.sk",
    "about you" => "aboutyou.sk",
    "hm" => "hm.com",
    "h&m" => "hm.com",
    "zara" => "zara.com",
    "decathlon" => "decathlon.sk",
    "pepco" => "pepco.sk",
    "kik" => "kik.sk",
    "action" => "action.com",

    # Predplatné a technológie
    "spotify" => "spotify.com",
    "netflix" => "netflix.com",
    "disney" => "disneyplus.com",
    "hbo" => "hbomax.com",
    "hbo max" => "hbomax.com",
    "youtube" => "youtube.com",
    "apple" => "apple.com",
    "icloud" => "apple.com",
    "google" => "google.com",
    "microsoft" => "microsoft.com",
    "adobe" => "adobe.com",
    "openai" => "openai.com",
    "chatgpt" => "openai.com",
    "canva" => "canva.com",
    "dropbox" => "dropbox.com",
    "steam" => "steampowered.com",
    "playstation" => "playstation.com",
    "xbox" => "xbox.com",
    "audible" => "audible.com",

    # Doprava
    "bolt" => "bolt.eu",
    "uber" => "uber.com",
    "hopin" => "hopin.sk",
    "slovnaft" => "slovnaft.sk",
    "omv" => "omv.sk",
    "shell" => "shell.com",
    "orlen" => "orlen.pl",
    "jurki" => "jurki.sk",
    "zssk" => "zssk.sk",
    "regiojet" => "regiojet.sk",
    "flixbus" => "flixbus.sk",
    "arriva" => "arriva.sk",
    "dpb" => "dpb.sk",
    "ryanair" => "ryanair.com",
    "wizz air" => "wizzair.com",
    "wizzair" => "wizzair.com",
    "booking" => "booking.com",
    "airbnb" => "airbnb.com",

    # Reštaurácie a jedlo
    "mcdonalds" => "mcdonalds.sk",
    "mcdonald" => "mcdonalds.sk",
    "kfc" => "kfc.sk",
    "burger king" => "burgerking.sk",
    "starbucks" => "starbucks.com",
    "costa" => "costacoffee.sk",
    "subway" => "subway.com",
    "bolt food" => "food.bolt.eu",
    "wolt" => "wolt.com",
    "foodpanda" => "foodpanda.sk",
    "bistro" => "bistro.sk",

    # Operátori a energie
    "orange" => "orange.sk",
    "telekom" => "telekom.sk",
    "o2" => "o2.sk",
    "4ka" => "4ka.sk",
    "vodafone" => "vodafone.sk",
    "zse" => "zse.sk",
    "sse" => "sse.sk",
    "vse" => "vsdistribucia.sk",
    "spp" => "spp.sk",
    "bvs" => "bvsas.sk",

    # Banky a financie
    "tatra banka" => "tatrabanka.sk",
    "tatrabanka" => "tatrabanka.sk",
    "slsp" => "slsp.sk",
    "slovenska sporitelna" => "slsp.sk",
    "vub" => "vub.sk",
    "csob" => "csob.sk",
    "mbank" => "mbank.sk",
    "unicredit" => "unicreditbank.sk",
    "365 bank" => "365.bank",
    "revolut" => "revolut.com",
    "wise" => "wise.com",
    "paypal" => "paypal.com",
    "n26" => "n26.com",
    "trading 212" => "trading212.com",
    "trading212" => "trading212.com",
    "xtb" => "xtb.com",
    "degiro" => "degiro.com",
    "interactive brokers" => "interactivebrokers.com",
    "binance" => "binance.com",
    "coinbase" => "coinbase.com",

    # Zábava a šport
    "cinema city" => "cinemacity.sk",
    "multikino" => "cine-max.sk",
    "cinemax" => "cine-max.sk",
    "ticketportal" => "ticketportal.sk",
    "predpredaj" => "predpredaj.sk",
    "fitinn" => "fitinn.sk",
    "multisport" => "multisport.sk"
  }.freeze

  # Emoji podľa kľúčových slov v názve transakcie (funguje aj pre slovenské výrazy)
  EMOJI_RULES = [
    [ /spotify/, "🎵" ],
    [ /netflix/, "📺" ],
    [ /kaufland|tesco|lidl|billa|jednota|terno/, "🛒" ],
    [ /\bdm\b|rossmann|teta/, "💄" ],
    [ /ikea|jysk|alza/, "🛍️" ],
    [ /bolt|uber/, "🚕" ],
    [ /starbucks|mcdonald|kfc/, "☕" ],
    [ /vyplata|mzda|\bplat\b|\bprijem|odmena|\bbonus\b/, "💰" ],
    [ /\burok|dividend|sporenie|\buspor/, "🏦" ],
    [ /najom|byvanie|hypotek|prenajom|ubytovanie/, "🏠" ],
    [ /elektrin|\bplyn\b|\bvoda\b|energi|kurenie/, "💡" ],
    [ /internet|\bmobil|telefon|pausal|operator/, "📱" ],
    [ /potravin|supermarket|\bobchod\b/, "🛒" ],
    [ /restaur|\bobed\b|\bvecer|\bkava\b|kaviaren|\bpizza\b|bistro|\bjedlo\b/, "🍽️" ],
    [ /benzin|\bnafta\b|tankovanie|palivo|cerpacia/, "⛽" ],
    [ /leasing|\bauto\b|\bauta\b|vozidlo|\bstk\b|\bpneu/, "🚗" ],
    [ /\bmhd\b|\bvlak|autobus|letenka|\btaxi\b|doprava|cestovne/, "🚌" ],
    [ /lekar|lekaren|zubar|zdravot|\bliek/, "💊" ],
    [ /\bkino\b|divadlo|koncert|zabava|festival/, "🎬" ],
    [ /predplatne|subscription|clensk/, "🔁" ],
    [ /fitness|posilnov|\bsport|\bbazen\b|wellness/, "🏋️" ],
    [ /\bskola\b|\bskolne\b|\bkurz|vzdelav|ucebnic/, "🎓" ],
    [ /darcek|\bdary\b|charita|prispevok/, "🎁" ],
    [ /oblecenie|\bobuv\b|\bmoda\b|drogeri|kozmetik/, "👕" ],
    [ /dovolenka|cestovanie|\bhotel|zajazd/, "✈️" ],
    [ /\bzviera|veterin|krmivo/, "🐾" ],
    [ /poisten|poistka/, "🛡️" ],
    [ /\bdane\b|\bdan\b|odvody|socialna poist/, "🧾" ],
    [ /splatka|\bplatba\b|payment|\bprevod\b|transfer|pozicka/, "💳" ],
    [ /investic|\bakcie\b|\betf\b|\bfond/, "📈" ],
    [ /\beshop\b|\bnakup/, "🛍️" ]
  ].freeze

  class << self
    # Vráti URL loga alebo nil, ak značku nepoznáme.
    def logo_url_for(name)
      logo_candidates_for(name).first
    end

    def logo_candidates_for(name)
      domain = domain_for(name)
      return [] unless domain

      [
        format(DUCKDUCKGO_URL, domain: domain),
        format(GOOGLE_URL, domain: domain)
      ]
    end

    def emoji_for(name)
      normalized = normalize(name)
      return nil if normalized.blank?

      EMOJI_RULES.each do |pattern, emoji|
        return emoji if normalized.match?(pattern)
      end

      nil
    end

    def domain_for(name)
      normalized = normalize(name)
      return nil if normalized.blank?

      return BRANDS[normalized] if BRANDS.key?(normalized)

      match = sorted_brand_keys.find { |key| contains_brand?(normalized, key) }
      match && BRANDS[match]
    end

    # Existuje pre tento názov nejaká vizuálna reprezentácia (logo alebo emoji)?
    def visual_for?(name)
      logo_url_for(name).present? || emoji_for(name).present?
    end

    private

      # "Kaufland Bratislava" -> "kaufland bratislava"
      # "DM drogéria"         -> "dm drogeria"
      def normalize(name)
        name.to_s
            .unicode_normalize(:nfd)
            .gsub(/\p{Mn}/, "")
            .downcase
            .gsub(/[^a-z0-9&\s]/, " ")
            .squish
      end

      # Najdlhšie kľúče prvé, aby "bolt food" vyhralo nad "bolt"
      def sorted_brand_keys
        @sorted_brand_keys ||= BRANDS.keys.sort_by { |key| -key.length }
      end

      # Značka musí byť samostatné slovo, aby "dm" nevyhralo v "admin"
      def contains_brand?(normalized, key)
        normalized.match?(/(?:\A|\s)#{Regexp.escape(key)}(?:\s|\z)/)
      end
  end

  # Vytvorí (alebo nájde) obchodníka pre transakciu a priradí mu logo.
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
        family = transaction.entry&.account&.family
        return nil unless family

        new(family: family, name: entry_name).assign_to(transaction)
      end
    end

    private

      def find_or_create_merchant
        logo_url = MerchantLogo.logo_url_for(@name)
        return nil unless logo_url

        existing = @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
        if existing
          existing.update!(logo_url: logo_url) if existing.logo_url != logo_url
          return existing
        end

        @family.merchants.create!(name: @name, logo_url: logo_url)
      rescue ActiveRecord::RecordInvalid
        @family.merchants.find_by("LOWER(name) = ?", @name.downcase)
      end
  end
end
