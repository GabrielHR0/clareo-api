# Append-only. Sem updated_by design: um log de auditoria que muda de estado
# não é log de auditoria.
class AuditLogRecord < ApplicationRecord
  self.table_name = "audit_logs"

  belongs_to :user_record, foreign_key: :user_id, optional: true

  ACTIONS = %w[create update delete login logout login_failed
               subaccount_created subaccount_approved subaccount_rejected
               charge_created charge_refunded split_blocked split_resolved
               payout_created payout_completed payout_failed
               webhook_reprocessed subscription_created subscription_cancelled].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :entity_type, presence: true

  scope :for_entity, ->(type, id) { where(entity_type: type, entity_id: id) }
  scope :recent, -> { order(created_at: :desc) }
end
