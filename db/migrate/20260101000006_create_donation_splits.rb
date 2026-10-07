class CreateDonationSplits < ActiveRecord::Migration[8.1]
  def change
    create_table :donation_splits do |t|
      t.references :donation, null: false, foreign_key: true
      t.references :institution, foreign_key: true

      t.string :recipient, null: false
      t.decimal :percentage, precision: 7, scale: 4, null: false

      t.string :status, null: false, default: "pending"
      t.decimal :total_value_brl, precision: 15, scale: 2
      t.string :asaas_split_id
      t.string :cancellation_reason

      t.timestamps
    end

    # t.references já cria os índices em donation_id e institution_id.
    add_index :donation_splits, :status

    add_check_constraint :donation_splits,
      "recipient IN ('institution', 'platform')",
      name: "donation_splits_recipient_check"

    add_check_constraint :donation_splits,
      "status IN ('pending', 'done', 'cancelled', 'blocked')",
      name: "donation_splits_status_check"

    add_check_constraint :donation_splits,
      "percentage > 0 AND percentage <= 100",
      name: "donation_splits_percentage_check"

    # A perna da instituição aponta para a instituição. A da plataforma fica na
    # conta emissora e por isso não tem instituição.
    add_check_constraint :donation_splits,
      <<~SQL.squish,
        (recipient = 'institution' AND institution_id IS NOT NULL) OR
        (recipient = 'platform' AND institution_id IS NULL)
      SQL
      name: "donation_splits_recipient_institution"
  end
end
