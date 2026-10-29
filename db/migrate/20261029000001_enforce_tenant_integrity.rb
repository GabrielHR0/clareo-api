class EnforceTenantIntegrity < ActiveRecord::Migration[8.1]
  def up
    add_index :accounts, [ :id, :institution_id ],
      unique: true,
      name: "idx_accounts_id_institution"
    add_index :cost_centers, [ :id, :institution_id ],
      unique: true,
      name: "idx_cost_centers_id_institution"
    add_index :posts, [ :id, :institution_id ],
      unique: true,
      name: "idx_posts_id_institution"
    add_index :donations, [ :id, :institution_id ],
      unique: true,
      name: "idx_donations_id_institution"
    add_index :donation_splits, [ :id, :institution_id ],
      unique: true,
      name: "idx_donation_splits_id_institution"

    execute <<~SQL
      ALTER TABLE ledger_entries
        ADD CONSTRAINT fk_ledger_entries_account_same_institution
        FOREIGN KEY (account_id, institution_id)
        REFERENCES accounts (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE ledger_entries
        ADD CONSTRAINT fk_ledger_entries_cost_center_same_institution
        FOREIGN KEY (cost_center_id, institution_id)
        REFERENCES cost_centers (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE ledger_entries
        ADD CONSTRAINT fk_ledger_entries_donation_split_same_institution
        FOREIGN KEY (donation_split_id, institution_id)
        REFERENCES donation_splits (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE donations
        ADD CONSTRAINT fk_donations_campaign_same_institution
        FOREIGN KEY (campaign_id, institution_id)
        REFERENCES campaigns (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE donation_splits
        ADD CONSTRAINT fk_donation_splits_donation_same_institution
        FOREIGN KEY (donation_id, institution_id)
        REFERENCES donations (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE payouts
        ADD CONSTRAINT fk_payouts_donation_same_institution
        FOREIGN KEY (donation_id, institution_id)
        REFERENCES donations (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE documents
        ADD CONSTRAINT fk_documents_ledger_entry_same_institution
        FOREIGN KEY (ledger_entry_id, institution_id)
        REFERENCES ledger_entries (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE documents
        ADD CONSTRAINT fk_documents_post_same_institution
        FOREIGN KEY (post_id, institution_id)
        REFERENCES posts (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE accountability_report_entries
        ADD CONSTRAINT fk_report_entries_account_same_institution
        FOREIGN KEY (account_id, institution_id)
        REFERENCES accounts (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE accountability_report_entries
        ADD CONSTRAINT fk_report_entries_campaign_same_institution
        FOREIGN KEY (campaign_id, institution_id)
        REFERENCES campaigns (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE accounts
        ADD CONSTRAINT fk_accounts_parent_same_institution
        FOREIGN KEY (institution_id, parent_code)
        REFERENCES accounts (institution_id, code)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE accounts DROP CONSTRAINT fk_accounts_parent_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE accountability_report_entries DROP CONSTRAINT fk_report_entries_campaign_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE accountability_report_entries DROP CONSTRAINT fk_report_entries_account_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE documents DROP CONSTRAINT fk_documents_post_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE documents DROP CONSTRAINT fk_documents_ledger_entry_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE payouts DROP CONSTRAINT fk_payouts_donation_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE donation_splits DROP CONSTRAINT fk_donation_splits_donation_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE donations DROP CONSTRAINT fk_donations_campaign_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE ledger_entries DROP CONSTRAINT fk_ledger_entries_donation_split_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE ledger_entries DROP CONSTRAINT fk_ledger_entries_cost_center_same_institution
    SQL
    execute <<~SQL
      ALTER TABLE ledger_entries DROP CONSTRAINT fk_ledger_entries_account_same_institution
    SQL

    remove_index :donation_splits, name: "idx_donation_splits_id_institution"
    remove_index :donations, name: "idx_donations_id_institution"
    remove_index :posts, name: "idx_posts_id_institution"
    remove_index :cost_centers, name: "idx_cost_centers_id_institution"
    remove_index :accounts, name: "idx_accounts_id_institution"
  end
end
