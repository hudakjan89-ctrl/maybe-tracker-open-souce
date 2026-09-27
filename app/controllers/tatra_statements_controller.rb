class TatraStatementsController < ApplicationController
  def new
    @account = selected_account
    @accounts = cash_accounts
  end

  def create
    @account = selected_account
    @accounts = cash_accounts
    file = params[:statement] || params.dig(:tatra_statement, :statement)

    unless @account
      flash.now[:alert] = "Najprv vytvorte účet, na ktorý sa majú transakcie nahrať."
      return render :new, status: :unprocessable_entity
    end

    unless file
      flash.now[:alert] = "Vložte CSV alebo PDF výpis z Tatra banky."
      return render :new, status: :unprocessable_entity
    end

    if file.size.to_i > 15.megabytes
      flash.now[:alert] = "Súbor je príliš veľký (maximum 15 MB)."
      return render :new, status: :unprocessable_entity
    end

    file.rewind if file.respond_to?(:rewind)

    result = TatraStatement::Importer.new(
      family: Current.family,
      account: @account,
      bytes: file.read,
      filename: file.original_filename
    ).call

    redirect_to transactions_path, notice: result.notice
  rescue TatraStatement::EmptyText, TatraStatement::NoTransactions, TatraStatement::Error => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private
    def cash_accounts
      Current.family.accounts.visible.where(accountable_type: "Depository").alphabetically
    end

    def selected_account
      Current.family.accounts.visible.find_by(id: params[:account_id] || params.dig(:tatra_statement, :account_id)) ||
        Current.family.default_cash_account
    end
end
