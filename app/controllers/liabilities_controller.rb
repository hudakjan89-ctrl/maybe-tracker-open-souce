class LiabilitiesController < ApplicationController
  before_action :set_liability, only: %i[edit update]

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: OtherLiability.new
    )
  end

  def create
    @account = Current.family.accounts.build(
      name: account_params[:name],
      balance: account_params[:balance],
      currency: Current.family.currency,
      accountable: OtherLiability.new
    )

    if @account.save
      @account.sync_later
      redirect_to root_path, notice: "Záväzok bol pridaný."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if account_params[:balance].present?
      result = @account.set_current_balance(account_params[:balance].to_d)
      unless result.success?
        @error_message = result.error_message
        return render :edit, status: :unprocessable_entity
      end
    end

    if @account.update(name: account_params[:name])
      @account.sync_later
      redirect_to root_path, notice: "Záväzok bol upravený."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

    def set_liability
      @account = Current.family.accounts.liabilities.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :balance, :currency)
    end
end
