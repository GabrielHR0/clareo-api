# O razão contábil da instituição: uma linha de receita ou de despesa.
#
# A distinção que faz a transparência auditável é origin:
# - donation: o sistema criou, porque o split foi liquidado pelo webhook. É
#   fato, não declaração, e é a âncora contra a qual tudo é conferido.
# - declared: a instituição escreveu.
#
# Immutable: uma entrada de donation nunca sai de posted e nunca é anulada. O
# dinheiro já entrou, e reescrever esse número é reescrever o que o banco
# registrou.
#
# campaign_id em donation é permitido e imutável, mas a instituição não o escolhe:
# ele vem do split, que vem do destino que o doador escolheu no checkout.
class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.bigint :institution_id, null: false
      t.bigint :account_id, null: false
      t.bigint :cost_center_id
      t.bigint :campaign_id
      t.string :kind, null: false
      t.string :origin, null: false
      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.string :description
      t.string :status, null: false, default: "draft"
      # Só preenchido quando origin = 'donation'. É a âncora da receita.
      t.bigint :donation_split_id
      t.string :void_reason
      t.date :posted_on

      t.timestamps
    end

    add_foreign_key :ledger_entries, :institutions
    add_foreign_key :ledger_entries, :accounts
    add_foreign_key :ledger_entries, :donation_splits

    add_index :ledger_entries, [ :institution_id, :posted_on ]
    add_index :ledger_entries, [ :institution_id, :status ]
    add_index :ledger_entries, [ :institution_id, :kind ]
    add_index :ledger_entries, :account_id
    add_index :ledger_entries, :cost_center_id
    add_index :ledger_entries, :campaign_id

    add_check_constraint :ledger_entries,
      "kind IN ('income', 'expense')",
      name: "ledger_entries_kind_check"

    add_check_constraint :ledger_entries,
      "origin IN ('donation', 'declared')",
      name: "ledger_entries_origin_check"

    add_check_constraint :ledger_entries,
      "status IN ('draft', 'posted', 'voided')",
      name: "ledger_entries_status_check"

    add_check_constraint :ledger_entries,
      "amount_brl >= 0",
      name: "ledger_entries_amount_check"

    # Uma linha por split. É o que impede a receita de aparecer duas vezes se o
    # webhook for reprocessado, que é o modo normal de entrega do provedor.
    add_index :ledger_entries, :donation_split_id,
      unique: true,
      where: "origin = 'donation'",
      name: "idx_ledger_entries_one_per_donation_split"

    # Receipto de sistema é income, sempre com split, e não volta de posted nem
    # aceita anulação: o dinheiro já entrou.
    add_check_constraint :ledger_entries,
      "origin <> 'donation' OR (kind = 'income' AND donation_split_id IS NOT NULL AND status = 'posted')",
      name: "ledger_entries_donation_shape_check"

    add_check_constraint :ledger_entries,
      "origin <> 'donation' OR void_reason IS NULL",
      name: "ledger_entries_donation_not_voided_check"

    # Anulação sempre justificável, senão o razão vira ficção: dá para apagar a
    # despesa sem deixar rastro do porquê.
    add_check_constraint :ledger_entries,
      "status <> 'voided' OR (void_reason IS NOT NULL AND length(btrim(void_reason)) > 0)",
      name: "ledger_entries_void_reason_check"

    # Split só em entrada de sistema.
    add_check_constraint :ledger_entries,
      "origin <> 'declared' OR donation_split_id IS NULL",
      name: "ledger_entries_declared_without_split_check"
  end
end
