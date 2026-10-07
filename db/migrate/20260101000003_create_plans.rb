class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.decimal :price_brl, precision: 10, scale: 2, null: false, default: 0
      t.integer :max_institutions
      t.jsonb :features, null: false, default: []

      t.timestamps
    end

    add_index :plans, :code, unique: true

    add_check_constraint :plans,
      "code IN ('free', 'pro', 'enterprise')",
      name: "plans_code_check"

    add_check_constraint :plans,
      "max_institutions IS NULL OR max_institutions > 0",
      name: "plans_max_institutions_check"

    add_check_constraint :plans, "price_brl >= 0", name: "plans_price_check"
  end
end
