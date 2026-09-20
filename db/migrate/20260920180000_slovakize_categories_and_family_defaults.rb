class SlovakizeCategoriesAndFamilyDefaults < ActiveRecord::Migration[7.2]
  # Anglický názov -> slovenský. Ak slovenská kategória v rodine už existuje,
  # transakcie sa do nej presunú a anglická sa zmaže.
  TRANSLATIONS = {
    "Income" => "Príjem",
    "Loan Payments" => "Splátky a poplatky",
    "Fees" => "Splátky a poplatky",
    "Entertainment" => "Zábava",
    "Food & Drink" => "Reštaurácie",
    "Shopping" => "Nákupy",
    "Home Improvement" => "Bývanie",
    "Rent & Utilities" => "Bývanie",
    "Healthcare" => "Zdravie",
    "Personal Care" => "Zdravie",
    "Services" => "Nákupy",
    "Gifts & Donations" => "Nákupy",
    "Transportation" => "Doprava",
    "Travel" => "Doprava"
  }.freeze

  def up
    change_column_default :families, :currency, from: "USD", to: "EUR"
    change_column_default :families, :locale, from: "en", to: "sk"
    change_column_default :families, :country, from: "US", to: "SK"
    change_column_default :families, :date_format, from: "%m-%d-%Y", to: "%d.%m.%Y"

    # Rodiny, ktoré nikdy nezmenili predvolené americké nastavenia
    execute <<~SQL
      UPDATE families
      SET currency = 'EUR', locale = 'sk', country = 'SK', date_format = '%d.%m.%Y'
      WHERE currency = 'USD' AND country = 'US'
    SQL

    TRANSLATIONS.each do |english, slovak|
      merge_or_rename(english, slovak)
    end
  end

  def down
    change_column_default :families, :currency, from: "EUR", to: "USD"
    change_column_default :families, :locale, from: "sk", to: "en"
    change_column_default :families, :country, from: "SK", to: "US"
    change_column_default :families, :date_format, from: "%d.%m.%Y", to: "%m-%d-%Y"
  end

  private

    def merge_or_rename(english, slovak)
      rows = select_all(<<~SQL).to_a
        SELECT en.id AS english_id, en.family_id, sk.id AS slovak_id
        FROM categories en
        LEFT JOIN categories sk
          ON sk.family_id = en.family_id AND sk.name = #{quote(slovak)}
        WHERE en.name = #{quote(english)}
      SQL

      rows.each do |row|
        if row["slovak_id"].nil?
          execute "UPDATE categories SET name = #{quote(slovak)} WHERE id = #{quote(row['english_id'])}"
        else
          merge_category(row["english_id"], row["slovak_id"])
        end
      end
    end

    def merge_category(from_id, to_id)
      from = quote(from_id)
      to = quote(to_id)

      execute "UPDATE transactions SET category_id = #{to} WHERE category_id = #{from}"
      execute "UPDATE rule_actions SET value = #{quote(to_id)} WHERE value = #{quote(from_id)}"
      execute "UPDATE categories SET parent_id = #{to} WHERE parent_id = #{from}"
      execute "DELETE FROM import_mappings WHERE mappable_type = 'Category' AND mappable_id = #{from}"

      # Rozpočtové položky sa dopočítajú znova pri zobrazení rozpočtu.
      execute "DELETE FROM budget_categories WHERE category_id = #{from}"
      execute "DELETE FROM categories WHERE id = #{from}"
    end

    def quote(value)
      connection.quote(value)
    end
end
