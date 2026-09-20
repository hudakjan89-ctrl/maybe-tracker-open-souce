class InviteCodesController < ApplicationController
  before_action :ensure_self_hosted

  def index
    @invite_codes = InviteCode.all
  end

  def create
    raise StandardError, "Nemáte oprávnenie generovať pozývacie kódy" unless Current.user.admin?
    InviteCode.generate!
    redirect_back_or_to invite_codes_path, notice: "Kód bol vygenerovaný."
  end

  private

    def ensure_self_hosted
      redirect_to root_path unless self_hosted?
    end
end
