class LiabilitiesController < ApplicationController
  before_action :set_liability, only: %i[edit update destroy payments record_payment create_payment paid_off]

  def new
    @account = Current.family.accounts.build(
      currency: Current.family.currency,
      accountable: OtherLiability.new
    )
  end

  def create
    @account = Current.family.accounts.create_and_sync(
      name: account_params[:name],
      balance: account_params[:balance],
      currency: Current.family.currency,
      accountable: OtherLiability.new
    )

    redirect_to root_path, notice: "Záväzok bol pridaný."
  rescue ActiveRecord::RecordInvalid
    @account = Current.family.accounts.new(
      name: account_params[:name],
      balance: account_params[:balance],
      currency: Current.family.currency,
      accountable: OtherLiability.new
    )
    @account.valid?
    render :new, status: :unprocessable_entity
  end

  def edit
  end

  def update
    if account_params[:balance].present?
      result = @account.set_current_balance(account_params[:balance].to_d)
      unless result.success?
        @error_message = result.error
        return render :edit, status: :unprocessable_entity
      end
    end

    if @account.update(name: account_params[:name])
      @account.sync_later
      return redirect_to_paid_off_or_root(@account, notice: "Záväzok bol upravený.")
    end

    render :edit, status: :unprocessable_entity
  end

  def destroy
    @account.destroy_later
    redirect_to root_path, notice: "Záväzok bol odstránený."
  end

  def payments
    @summary = Liability::RepaymentSummary.new(@account)
  end

  def record_payment
    return redirect_to payments_liability_path(@account) if @account.disabled?

    @summary = Liability::RepaymentSummary.new(@account)
    @source_accounts = Current.family.accounts.visible.where(accountable_type: "Depository").alphabetically
  end

  def create_payment
    return redirect_to payments_liability_path(@account), alert: "Tento záväzok je už splatený." if @account.disabled?
    result = Liability::PaymentRecorder.new(
      family: Current.family,
      liability: @account,
      amount: payment_params[:amount],
      date: payment_params[:date],
      source_account_id: payment_params[:from_account_id]
    ).record

    unless result.success?
      @summary = Liability::RepaymentSummary.new(@account)
      @source_accounts = Current.family.accounts.visible.where(accountable_type: "Depository").alphabetically
      @error_message = result.error
      return render :record_payment, status: :unprocessable_entity
    end

    @account.reload
    redirect_to_paid_off_or_root(@account, notice: "Platba bola zaznamenaná.")
  end

  def paid_off
    @summary = Liability::RepaymentSummary.new(@account)
  end

  private

    def set_liability
      @account = Current.family.accounts.liabilities.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :balance, :currency)
    end

    def payment_params
      params.require(:payment).permit(:amount, :date, :from_account_id)
    end

    def redirect_to_paid_off_or_root(account, notice:)
      account.reload
      if account.balance.to_d <= 0 && account.may_disable?
        Liability::PaidOff.mark!(account)
        redirect_to paid_off_liability_path(account), notice: notice
      else
        redirect_to root_path, notice: notice
      end
    end
end
