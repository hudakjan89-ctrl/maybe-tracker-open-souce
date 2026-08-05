class DemoTransactionsController < ApplicationController
  def create
    Demo::SampleTransactions.new(Current.family).generate!

    redirect_to root_path, notice: "Testovacie transakcie boli úspešne vytvorené."
  rescue => e
    Rails.logger.error("Demo transactions failed: #{e.class} - #{e.message}\n#{e.backtrace.first(10).join("\n")}")
    redirect_to root_path, alert: "Nepodarilo sa vytvoriť testovacie dáta: #{e.message}"
  end
end
