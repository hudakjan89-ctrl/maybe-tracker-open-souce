class TatraStatement::Categorizer
  RULES = [
    [ /v[yý]plata|\bmzda\b|\bplat\b|salary|paycheck|[uú]rok zo|dividenda/i, "Plat" ],
    [ /kaufland|tesco|lidl|billa|yeme|terno|coop|jednota|fresh|potravin|grocery|lidl/i, "Potraviny" ],
    [ /spotify|netflix|disney|youtube|icloud|apple\.com|predplat|hbo|canva|openai|chatgpt/i, "Predplatné" ],
    [ /slovnaft|omv|\bshell\b|benz|phm|tankov|leasing|doprav|parkov|pps|\bvlak\b|regiojet|\buber\b|\bbolt\b|autobus|mhd/i, "Doprava" ],
    [ /n[aá]jom|b[yý]vanie|energie|\bzse\b|\bspp\b|vod[aá]rne|internet|orange|telekom|\bo2\b|\bupc\b|anto|v[yý]tah/i, "Bývanie" ],
    [ /alza|ikea|zalando|zara|pepco|\bkik\b|action|\bdm\b|rossmann|teta|datart|\bnay\b|about you|decathlon/i, "Nákupy" ]
  ].freeze

  def initialize(family)
    @categories = family.categories.index_by(&:name)
  end

  def category_for(name)
    RULES.each do |pattern, category_name|
      return @categories[category_name] if name.to_s.match?(pattern)
    end
    nil
  end
end
