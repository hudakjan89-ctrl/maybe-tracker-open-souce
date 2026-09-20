class Rule::ActionExecutor
  TYPES = [ "select", "function", "text" ]

  LABELS = {
    "set_transaction_category" => "Nastaviť kategóriu",
    "set_transaction_merchant" => "Nastaviť obchodníka",
    "set_transaction_name" => "Nastaviť názov",
    "set_transaction_tags" => "Nastaviť štítky"
  }.freeze

  def initialize(rule)
    @rule = rule
  end

  def key
    self.class.name.demodulize.underscore
  end

  def label
    LABELS.fetch(key, key.humanize)
  end

  def type
    "function"
  end

  def options
    nil
  end

  def execute(scope, value: nil, ignore_attribute_locks: false)
    raise NotImplementedError, "Action executor #{self.class.name} must implement #execute"
  end

  def as_json
    {
      type: type,
      key: key,
      label: label,
      options: options
    }
  end

  private
    attr_reader :rule

    def family
      rule.family
    end
end
