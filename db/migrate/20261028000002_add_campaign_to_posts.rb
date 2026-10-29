class AddCampaignToPosts < ActiveRecord::Migration[8.1]
  def up
    # A FK composta garante que o post e a campanha pertencem ao mesmo tenant.
    # Um post de uma instituição não pode apontar para campanha de outra.
    add_index :campaigns, [ :id, :institution_id ],
      unique: true,
      name: "idx_campaigns_id_institution"

    add_column :posts, :campaign_id, :bigint
    add_index :posts, :campaign_id

    execute <<~SQL
      ALTER TABLE posts
        ADD CONSTRAINT fk_posts_campaign_same_institution
        FOREIGN KEY (campaign_id, institution_id)
        REFERENCES campaigns (id, institution_id)
    SQL

    # O razão já tinha campaign_id desde 00008. Fechar a mesma integridade
    # multitenant agora evita que um lançamento aponte para campanha alheia.
    execute <<~SQL
      ALTER TABLE ledger_entries
        ADD CONSTRAINT fk_ledger_entries_campaign_same_institution
        FOREIGN KEY (campaign_id, institution_id)
        REFERENCES campaigns (id, institution_id)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE ledger_entries DROP CONSTRAINT fk_ledger_entries_campaign_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE posts DROP CONSTRAINT fk_posts_campaign_same_institution
    SQL
    remove_column :posts, :campaign_id
    remove_index :campaigns, name: "idx_campaigns_id_institution"
  end
end
