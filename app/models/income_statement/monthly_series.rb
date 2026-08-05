class IncomeStatement::MonthlySeries
  def initialize(family, period:)
    @family = family
    @period = period
  end

  def call
    rows = ActiveRecord::Base.connection.select_all(sanitized_sql)
    months = {}

    rows.each do |row|
      month_key = row["month"].to_date.strftime("%Y-%m")
      months[month_key] ||= { label: format_month(row["month"].to_date), income: [], expense: [] }

      classification = row["classification"]
      next if row["total"].to_f.zero?

      months[month_key][classification.to_sym] << {
        name: row["category_name"] || "Bez kategórie",
        color: row["category_color"] || Category::UNCATEGORIZED_COLOR,
        value: row["total"].to_f.round(2)
      }
    end

    months.sort.map do |key, data|
      income_total = data[:income].sum { |c| c[:value] }
      expense_total = data[:expense].sum { |c| c[:value] }

      {
        key: key,
        label: data[:label],
        income: { total: income_total.round(2), categories: data[:income] },
        expense: { total: expense_total.round(2), categories: data[:expense] }
      }
    end
  end

  private

    def sanitized_sql
      ActiveRecord::Base.sanitize_sql_array([
        query_sql,
        {
          family_id: @family.id,
          start_date: @period.start_date,
          end_date: @period.end_date,
          target_currency: @family.currency
        }
      ])
    end

    def query_sql
      <<~SQL
        SELECT
          date_trunc('month', ae.date) as month,
          c.id as category_id,
          c.name as category_name,
          c.color as category_color,
          CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END as classification,
          ABS(SUM(ae.amount * COALESCE(er.rate, 1))) as total
        FROM transactions t
        JOIN entries ae ON ae.entryable_id = t.id AND ae.entryable_type = 'Transaction'
        JOIN accounts a ON a.id = ae.account_id
        LEFT JOIN categories c ON c.id = t.category_id
        LEFT JOIN exchange_rates er ON (
          er.date = ae.date AND
          er.from_currency = ae.currency AND
          er.to_currency = :target_currency
        )
        WHERE a.family_id = :family_id
          AND ae.date BETWEEN :start_date AND :end_date
          AND t.kind NOT IN ('funds_movement', 'one_time', 'cc_payment')
          AND ae.excluded = false
        GROUP BY month, c.id, c.name, c.color, CASE WHEN ae.amount < 0 THEN 'income' ELSE 'expense' END
        ORDER BY month
      SQL
    end

    def format_month(date)
      I18n.l(date, format: "%b %Y")
    end
end
