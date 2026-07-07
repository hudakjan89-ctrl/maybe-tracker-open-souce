class ProviderMerchant < ApplicationRecord
  enum :source, { rule: "rule" }
end
