# Plano de contas da instituição.
#
# Não existe tabela global de contas: o catálogo padrão é semeado em cada
# instituição quando ela é criada, porque o plano de contas é do tenant. Por isso
# a unicidade do código é por (institution_id, code) e não só por code.
#
# A hierarquia é referenciada por parent_code, e não por parent_id, porque o
# catálogo padrão é dado puro: não pode depender de ids que o banco ainda não
# atribuiu. A consistência "todo pai existe" é garantida pelo domínio e por
# spec, não pelo banco.
class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.bigint :institution_id, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.string :nature, null: false
      t.string :parent_code
      # system: veio do catálogo padrão. A conta de receita de doação é system e
      # a receita automática do split aponta para ela por código.
      t.boolean :system, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_foreign_key :accounts, :institutions

    add_index :accounts, [ :institution_id, :code ], unique: true
    add_index :accounts, [ :institution_id, :parent_code ]
    add_index :accounts, [ :institution_id, :nature ]

    add_check_constraint :accounts,
      "nature IN ('income', 'expense')",
      name: "accounts_nature_check"

    add_check_constraint :accounts,
      "parent_code IS NULL OR parent_code <> code",
      name: "accounts_not_own_parent_check"
  end
end
