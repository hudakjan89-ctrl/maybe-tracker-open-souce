# Dynamic settings the user can change within the app
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  field :require_invite_for_signup, type: :boolean, default: false
  field :require_email_confirmation, type: :boolean, default: ENV.fetch("REQUIRE_EMAIL_CONFIRMATION", "true") == "true"
end
