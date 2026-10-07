module Persistence
  # Implementa Repositories::WebhookEventRepository.
  #
  # A entrega do provedor é at least once. Este repositório é o que torna o
  # duplicado inofensivo: record falha em vez de duplicar, e todo mundo no
  # sistema trata isso como "já vi esse evento".
  class WebhookEventRepository
    def find_by_provider_event_id(provider_event_id)
      record = WebhookEventRecord.find_by(provider_event_id: provider_event_id.to_s)
      record && RecordMapper.record_to_webhook_event(record)
    end

    # @return [Boolean] true quando gravou, false quando o evento já existia
    def record(provider_event_id:, event:, payload:, resource_id:, resource_type:)
      WebhookEventRecord.record_once(
        provider_event_id: provider_event_id,
        event: event,
        payload: payload,
        resource_type: resource_type,
        resource_id: resource_id
      )
    end

    def mark_processing(provider_event_id)
      update(provider_event_id) do |record|
        record.update!(
          status: "processing",
          attempts: record.attempts + 1,
          error_message: nil
        )
      end
    end

    def mark_processed(provider_event_id)
      update(provider_event_id) do |record|
        record.update!(status: "processed", processed_at: Time.current)
      end
    end

    def mark_failed(provider_event_id, error_message)
      update(provider_event_id) do |record|
        record.update!(status: "failed", error_message: error_message.to_s.truncate(2000))
      end
    end

    private

    # O domínio só conhece o id do provedor: ele é a chave de idempotência.
    # O id interno do record não atravessa a fronteira.
    def update(provider_event_id)
      record = WebhookEventRecord.find_by!(provider_event_id: provider_event_id.to_s)
      yield record
      record
    end
  end
end
