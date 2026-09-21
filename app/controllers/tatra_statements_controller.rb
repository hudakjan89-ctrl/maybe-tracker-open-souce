class TatraStatementsController < ApplicationController
  def new
    @accounts = Current.family.accounts.visible.alphabetically
  end

  def create
    @accounts = Current.family.accounts.visible.alphabetically
    account = @accounts.find_by(id: params[:account_id] || params.dig(:tatra_statement, :account_id))
    file = params[:statement] || params.dig(:tatra_statement, :statement)

    unless account
      flash.now[:alert] = "Vyberte účet, na ktorý sa majú transakcie nahrať."
      return render :new, status: :unprocessable_entity
    end

    unless file
      flash.now[:alert] = "Nahrajte PDF (alebo CSV/TXT) výpis z Tatra banky."
      return render :new, status: :unprocessable_entity
    end

    if file.size.to_i > 15.megabytes
      flash.now[:alert] = "Súbor je príliš veľký (maximum 15 MB)."
      return render :new, status: :unprocessable_entity
    end

    file.rewind if file.respond_to?(:rewind)

    result = TatraStatement::Importer.new(
      family: Current.family,
      account: account,
      bytes: file.read,
      filename: file.original_filename
    ).call

    redirect_to transactions_path, notice: result.notice
  rescue TatraStatement::EmptyText, TatraStatement::NoTransactions, TatraStatement::Error => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end
end
