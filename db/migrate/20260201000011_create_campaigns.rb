# Campanha: meta de arrecadação com destino de recurso.
#
# Não tem current_amount nem applied_amount. O legado tinha current_amount
# guardado, e isso é cache que dessincroniza e vira mentira silenciosa: se o
# split for estornado, a meta continua anunciando um valor que não existe mais.
# Os dois são derivados dos lançamentos.
#
# Sem current_amount, a campanha também não precisa de serviço para recalcular:
# raised vem dos lançamentos de origin=donation e applied dos de origin=declared.
class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.bigint :institution_id, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :goal_brl, precision: 15, scale: 2, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_foreign_key :campaigns, :institutions

    # Índice do feed público: campanhas ativas por instituição, da mais recente.
    add_index :campaigns, [ :institution_id, :status ]
    add_index :campaigns, [ :institution_id, :ends_on ]

    add_check_constraint :campaigns,
      "status IN ('active', 'paused', 'closed')",
      name: "campaigns_status_check"

    add_check_constraint :campaigns,
      "goal_brl > 0",
      name: "campaigns_goal_check"

    add_check_constraint :campaigns,
      "ends_on >= starts_on",
      name: "campaigns_period_check"

    # A FK do campaign_id do razão só pode nascer agora, porque a tabela alvo
    # acabou de ser criada. LedgerEntry.campaign_id já existia sem integridade
    # desde 00008; este é o momento de fechar.
    add_foreign_key :ledger_entries, :campaigns
  end
end
