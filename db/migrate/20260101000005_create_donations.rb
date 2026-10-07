class CreateDonations < ActiveRecord::Migration[8.1]
  def change
    create_table :donations do |t|
      t.references :institution, null: false, foreign_key: true

      t.string :donor_name, null: false
      t.string :donor_email

      t.decimal :amount_brl, precision: 15, scale: 2, null: false
      t.string :payment_method, null: false
      t.string :status, null: false, default: "pending"

      t.string :reference, null: false
      t.string :asaas_payment_id
      t.string :asaas_customer_id

      # Preenchido no webhook, nunca antes: a taxa do provedor é contratual.
      t.decimal :net_amount_brl, precision: 15, scale: 2
      t.datetime :received_at
      t.datetime :refunded_at

      t.timestamps
    end

    add_index :donations, :status
    add_index :donations, :donor_email
    add_index :donations, :asaas_payment_id
    add_index :donations, :created_at

    # Chave de idempotência: o provedor aceita cobranças duplicadas sem reclamar.
    add_index :donations, :reference, unique: true

    add_check_constraint :donations,
      "payment_method IN ('pix', 'boleto', 'credit_card')",
      name: "donations_payment_method_check"

    add_check_constraint :donations,
      "status IN ('pending', 'received', 'refunded', 'cancelled', 'rejected', 'split_blocked')",
      name: "donations_status_check"

    add_check_constraint :donations, "amount_brl > 0", name: "donations_amount_positive"

    add_check_constraint :donations,
      "net_amount_brl IS NULL OR net_amount_brl >= 0",
      name: "donations_net_amount_check"
  end
end
