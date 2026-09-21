class AccountsController < ApplicationController
  before_action :set_account, only: %i[sync sparkline toggle_active show destroy]
  include Periodable

  def index
    @accounts = family.accounts.alphabetically

    render layout: "settings"
  end

  def sync_all
    family.sync_later
    redirect_to accounts_path, notice: "Účty sa synchronizujú..."
  end

  def show
    @chart_view = params[:chart_view] || "balance"
    @tab = params[:tab]
    @q = params.fetch(:q, {}).permit(:search)
    entries = @account.entries.search(@q).reverse_chronological

    @pagy, @entries = pagy(entries, limit: params[:per_page] || "10")

    @activity_feed_data = Account::ActivityFeedData.new(@account, @entries)
  end

  def sync
    unless @account.syncing?
      @account.sync_later
    end

    redirect_to account_path(@account)
  end

  def sparkline
    etag_key = @account.family.build_cache_key("#{@account.id}_sparkline", invalidate_on_data_updates: true)

    if stale?(etag: etag_key, last_modified: @account.family.latest_sync_completed_at)
      @sparkline_series = @account.sparkline_series
      render layout: false
    end
  end

  def toggle_active
    if @account.active?
      @account.disable!
    elsif @account.disabled?
      @account.enable!
    end
    redirect_to accounts_path
  end

  def destroy
    name = @account.name
    @account.destroy!
    redirect_to accounts_path, notice: "Účet „#{name}“ a súvisiace prevody boli zmazané."
  rescue => e
    Rails.logger.error("[Accounts] destroy failed: #{e.class}: #{e.message}")
    redirect_to accounts_path, alert: "Účet sa nepodarilo zmazať. Skúste to znova."
  end

  private
    def family
      Current.family
    end

    def set_account
      @account = family.accounts.find(params[:id])
    end
end
