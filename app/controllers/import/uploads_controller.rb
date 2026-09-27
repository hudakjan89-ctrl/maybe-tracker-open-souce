class Import::UploadsController < ApplicationController
  layout "imports"

  before_action :set_import

  def show
  end

  def sample_csv
    send_data @import.csv_template.to_csv,
      filename: "#{@import.type.underscore.split('_').first}_sample.csv",
      type: "text/csv",
      disposition: "attachment"
  end

  def update
    if tatra_upload?
      return import_tatra_statement!
    end

    if csv_valid?(csv_str)
      @import.account = Current.family.accounts.find_by(id: params.dig(:import, :account_id))
      @import.assign_attributes(raw_file_str: csv_str, col_sep: upload_params[:col_sep])
      @import.save!(validate: false)

      redirect_to import_configuration_path(@import, template_hint: true), notice: "Súbor CSV bol nahratý."
    else
      flash.now[:alert] = "Súbor musí byť platné CSV s hlavičkou a aspoň jedným riadkom údajov."

      render :show, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing
    flash.now[:alert] = "Vložte CSV alebo PDF výpis z Tatra banky."
    render :show, status: :unprocessable_entity
  rescue => e
    Rails.logger.error("[Import::Uploads] #{e.class}: #{e.message}\n#{e.backtrace.first(12).join("\n")}")
    flash.now[:alert] = "Súbor sa nepodarilo spracovať. Skúste to cez tlačidlo Vložiť výpis."
    render :show, status: :unprocessable_entity
  end

  private
    def set_import
      @import = Current.family.imports.find(params[:import_id])
    end

    def uploaded_bytes
      @uploaded_bytes ||= begin
        file = upload_params[:csv_file]
        if file.respond_to?(:read)
          file.rewind if file.respond_to?(:rewind)
          file.read
        else
          upload_params[:raw_file_str].to_s
        end
      end
    end

    def csv_str
      @csv_str ||= TatraStatement.decode(uploaded_bytes)
    end

    def tatra_upload?
      filename = upload_params[:csv_file]&.original_filename.to_s.downcase
      bytes = uploaded_bytes.to_s
      TatraStatement::CsvParser.handles?(bytes) ||
        filename.end_with?(".pdf") ||
        bytes.start_with?("%PDF")
    rescue ActionController::ParameterMissing
      false
    end

    def import_tatra_statement!
      account = Current.family.accounts.visible.find_by(id: params.dig(:import, :account_id)) ||
        @import.account ||
        Current.family.default_cash_account
      unless account
        flash.now[:alert] = "Najprv vytvorte účet, na ktorý sa majú transakcie nahrať."
        return render :show, status: :unprocessable_entity
      end

      filename = upload_params[:csv_file]&.original_filename.presence || "vypis.csv"
      result = TatraStatement::Importer.new(
        family: Current.family,
        account: account,
        bytes: uploaded_bytes,
        filename: filename
      ).call

      @import.destroy
      redirect_to transactions_path, notice: result.notice
    rescue TatraStatement::EmptyText, TatraStatement::NoTransactions, TatraStatement::Error => e
      flash.now[:alert] = e.message
      render :show, status: :unprocessable_entity
    end

    def csv_valid?(str)
      csv = Import.parse_csv_str(str, col_sep: upload_params[:col_sep])
      return false if csv.headers.empty?
      return false if csv.count == 0
      true
    rescue CSV::MalformedCSVError, ArgumentError, EncodingError
      false
    end

    def upload_params
      params.require(:import).permit(:raw_file_str, :csv_file, :col_sep)
    end
end
