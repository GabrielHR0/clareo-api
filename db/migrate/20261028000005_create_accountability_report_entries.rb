class CreateAccountabilityReportEntries < ActiveRecord::Migration[8.1]
  def up
    # Chave composta para a FK de tenant do snapshot.
    add_index :ledger_entries, [ :id, :institution_id ],
      unique: true,
      name: "idx_ledger_entries_id_institution"

    create_table :accountability_report_entries do |t|
      t.bigint :institution_id, null: false
      t.bigint :accountability_report_id, null: false
      t.bigint :ledger_entry_id, null: false
      t.bigint :account_id, null: false
      t.bigint :campaign_id
      t.string :kind, null: false
      t.string :origin, null: false
      t.string :account_code, null: false
      t.string :account_name, null: false
      t.string :description
      t.date :posted_on, null: false
      t.decimal :amount_brl, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :accountability_report_entries,
      [ :accountability_report_id, :ledger_entry_id ],
      unique: true,
      name: "idx_report_entries_one_per_ledger_entry"
    add_index :accountability_report_entries, [ :institution_id, :posted_on ]
    add_index :accountability_report_entries, :ledger_entry_id
    add_index :accountability_report_entries, :campaign_id

    add_foreign_key :accountability_report_entries, :institutions
    add_foreign_key :accountability_report_entries, :accounts
    add_foreign_key :accountability_report_entries, :campaigns

    # O relatório e o lançamento precisam ser do mesmo tenant do snapshot.
    execute <<~SQL
      ALTER TABLE accountability_report_entries
        ADD CONSTRAINT fk_report_entries_report_same_institution
        FOREIGN KEY (accountability_report_id, institution_id)
        REFERENCES accountability_reports (id, institution_id)
    SQL

    execute <<~SQL
      ALTER TABLE accountability_report_entries
        ADD CONSTRAINT fk_report_entries_ledger_same_institution
        FOREIGN KEY (ledger_entry_id, institution_id)
        REFERENCES ledger_entries (id, institution_id)
    SQL

    add_check_constraint :accountability_report_entries,
      "kind IN ('income', 'expense')",
      name: "accountability_report_entries_kind_check"

    add_check_constraint :accountability_report_entries,
      "origin IN ('donation', 'declared')",
      name: "accountability_report_entries_origin_check"

    add_check_constraint :accountability_report_entries,
      "amount_brl >= 0",
      name: "accountability_report_entries_amount_check"
  end

  def down
    drop_table :accountability_report_entries
    remove_index :ledger_entries, name: "idx_ledger_entries_id_institution"
  end
end
