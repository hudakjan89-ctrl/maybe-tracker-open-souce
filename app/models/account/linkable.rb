module Account::Linkable
  extend ActiveSupport::Concern

  def linked?
    false
  end

  def unlinked?
    true
  end
  alias_method :manual?, :unlinked?
end
