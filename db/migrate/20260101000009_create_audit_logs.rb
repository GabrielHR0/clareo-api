class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.string :action, null: false
      t.string :entity_type, null: false
      t.bigint :entity_id
      t.jsonb :metadata
      t.string :ip_address, limit: 45
      t.references :user, foreign_key: true

      # Sem updated_at: log de auditoria é append-only.
      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [ :entity_type, :entity_id ], name: "idx_audit_logs_entity"
    # t.references já cria o índice em user_id.
    add_index :audit_logs, :created_at
  end
end
