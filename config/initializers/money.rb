# Aplikácia beží v eurách — bez tohto by sa sumy bez explicitnej meny
# vykreslili v dolároch (pôvodná predvolená mena knižnice).
Rails.application.config.to_prepare do
  Money.default_currency = "EUR"
end
