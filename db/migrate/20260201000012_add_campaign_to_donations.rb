# O doador pode escolher o destino da doação no checkout: o recurso vai para
# uma campanha específica em vez de entrar na receita geral.
#
# A informação nasce aqui e não no razão, porque a receita do sistema é criada a
# partir do split, e o split não sabe de campanha. LedgerEntry.campaign_id copia
# este valor e é imutável, então a instituição não move dinheiro de campanha
# depois do fato.
#
# Nullable: a maioria das doações não tem destino escolhido.
class AddCampaignToDonations < ActiveRecord::Migration[8.1]
  def up
    add_column :donations, :campaign_id, :bigint
    add_foreign_key :donations, :campaigns
    add_index :donations, :campaign_id
  end

  def down
    remove_index :donations, :campaign_id
    remove_foreign_key :donations, :campaign_id
    remove_column :donations, :campaign_id
  end
end
