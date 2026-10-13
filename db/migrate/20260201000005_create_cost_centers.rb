# Centro de custo, para separar o mesmo gasto entre projetos. É o que sustenta a
# rastreabilidade que a governança exige: "dos R$ 10 mil da campanha, quanto foi
# para material e quanto para pessoal?".
class CreateCostCenters < ActiveRecord::Migration[8.1]
  def change
    create_table :cost_centers do |t|
      t.bigint :institution_id, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_foreign_key :cost_centers, :institutions

    add_index :cost_centers, [ :institution_id, :code ], unique: true
    add_index :cost_centers, [ :institution_id, :active ]
  end
end
