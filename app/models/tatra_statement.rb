# Import pohybov z výpisu Tatra banky (CSV z Histórie pohybov, PDF alebo skopírovaný text).
module TatraStatement
  class Error < StandardError; end
  class EmptyText < Error; end
  class NoTransactions < Error; end
end
