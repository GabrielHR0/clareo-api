class CreatePayouts < ActiveRecord::Migration[8.1]
  def change
    create_table :payouts do |t|
      t.references :institution, null: false, foreign_key: true
      t.references :donation, foreign_key: true

      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.string :pix_key, null: false
      t.string :provider_transfer_id

      t.string :status, null: false, default: "pending"
      t.text :failure_reason
      t.datetime :completed_at

      t.timestamps
    end

    add_index :payouts, :status
    add_index :payouts, :provider_transfer_id

    # Um payout por (donation, institution). Sem este índice, um retry de job
    # poderia pagar a instituição duas vezes, que é o erro mais caro possível
    # num produto que movimenta dinheiro de terceiros.
    add_index :payouts, [ :donation_id, :institution_id ],
      unique: true,
      where: "donation_id IS NOT NULL",
      name: "idx_payouts_one_per_donation"

    add_check_constraint :payouts,
      "status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')",
      name: "payouts_status_check"

    add_check_constraint :payouts, "amount_brl > 0", name: "payouts_amount_positive"
  end
end
