# The shape of data expected by `confirm_dialog_controller.js` to override the
# default browser confirm API via Turbo.
#
# `resource_name` sa vkladá do vety „Naozaj chcete zmazať …?“, preto ho volajúci
# posiela už v akuzatíve (napr. „túto transakciu“, „všetky štítky“).
class CustomConfirm
  class << self
    def for_resource_deletion(resource_name, high_severity: false)
      new(
        destructive: true,
        high_severity: high_severity,
        title: "Zmazať #{resource_name}?",
        body: "Naozaj chcete zmazať #{resource_name}? Túto akciu nie je možné vrátiť späť.",
        btn_text: "Zmazať"
      )
    end
  end

  def initialize(title: default_title, body: default_body, btn_text: default_btn_text, destructive: false, high_severity: false)
    @title = title
    @body = body
    @btn_text = btn_text
    @btn_variant = derive_btn_variant(destructive, high_severity)
  end

  def to_data_attribute
    {
      title: title,
      body: body,
      confirmText: btn_text,
      variant: btn_variant
    }
  end

  private
    attr_reader :title, :body, :btn_text, :btn_variant

    def derive_btn_variant(destructive, high_severity)
      return "primary" unless destructive
      high_severity ? "destructive" : "outline-destructive"
    end

    def default_title
      "Ste si istí?"
    end

    def default_body
      "Túto akciu nie je možné vrátiť späť."
    end

    def default_btn_text
      "Potvrdiť"
    end
end
