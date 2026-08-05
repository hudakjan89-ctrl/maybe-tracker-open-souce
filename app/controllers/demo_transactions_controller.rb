class DemoTransactionsController < ApplicationController
  def create
    Demo::SampleTransactions.new(Current.family).generate!

    redirect_to root_path, notice: "Testovacie transakcie boli úspešne vytvorené."
  end
end
