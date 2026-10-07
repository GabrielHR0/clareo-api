class CreateWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events do |t|
      # O provedor entrega at least once. Este é o que torna o duplicado
      # fisicamente impossível, não apenas improvável.
      t.string :provider_event_id, null: false, limit: 128
      t.string :provider, null: false, default: "asaas"
      t.string :event, null: false
      t.string :resource_type
      t.string :resource_id
      t.jsonb :payload, null: false

      t.string :status, null: false, default: "received"
      t.integer :attempts, null: false, default: 0
      t.datetime :processed_at
      t.text :error_message

      t.timestamps
    end

    add_index :webhook_events, :status
    add_index :webhook_events, [ :resource_type, :resource_id ], name: "idx_webhook_events_resource"
    add_index :webhook_events, :created_at

    add_index :webhook_events, :provider_event_id, unique: true

    add_check_constraint :webhook_events,
      "status IN ('received', 'processing', 'processed', 'failed')",
      name: "webhook_events_status_check"
  end
end
