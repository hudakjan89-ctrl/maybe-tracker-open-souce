# Import pohybov z výpisu Tatra banky (PDF, CSV alebo skopírovaný text).
module TatraStatement
  class Error < StandardError; end
  class EmptyText < Error; end
  class NoTransactions < Error; end
end
