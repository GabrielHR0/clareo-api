class WebhookEventRecord < ApplicationRecord
  self.table_name = "webhook_events"

  STATUSES = %w[received processing processed failed].freeze

  # Sem validação de unicidade aqui de propósito. A garantia de idempotência é
  # o índice único do banco: uma validação de model curaria o caso comum antes
  # do índice, mas não protege contra corrida, e faria a deduplicação tratar
  # RecordInvalid em vez de RecordNotUnique.
  validates :provider_event_id, presence: true
  validates :event, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :failed, -> { where(status: "failed") }
  scope :unprocessed, -> { where(status: %w[received failed]) }

  # INSERT idempotente. O índice único em provider_event_id faz o duplicado
  # ser fisicamente impossível: a entrega do provedor é at least once.
  #
  # Retorna true quando gravou, false quando o evento já existia.
  def self.record_once(provider_event_id:, event:, payload:, resource_type:, resource_id:, provider: "asaas")
    create!(
      provider_event_id: provider_event_id,
      provider: provider,
      event: event,
      payload: payload,
      resource_type: resource_type,
      resource_id: resource_id
    )
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end
end
