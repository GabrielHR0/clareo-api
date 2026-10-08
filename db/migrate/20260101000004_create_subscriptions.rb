class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true

      t.string :asaas_subscription_id
      t.string :status, null: false, default: "active"
      t.datetime :current_period_ends_at
      t.datetime :cancelled_at

      t.timestamps
    end

    # Índice parcial: uma assinatura ativa por usuário. A regra não pode
    # depender só da aplicação.
    add_index :subscriptions, :user_id,
      unique: true,
      where: "status = 'active'",
      name: "idx_subscriptions_one_active_per_user"

    add_index :subscriptions, :asaas_subscription_id

    add_check_constraint :subscriptions,
      "status IN ('active', 'past_due', 'cancelled', 'expired')",
      name: "subscriptions_status_check"
  end
end
