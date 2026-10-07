module Repositories
# Webhook delivery is at least once, so the provider event id is the
# idempotency key. Saving twice must be impossible, not merely unlikely.
class WebhookEventRepository
  # @return [WebhookEvent, nil]
  def find_by_provider_event_id(provider_event_id)
    raise NotImplementedError
  end

  # @return [Boolean] true when persisted, false when already seen
  def record(provider_event_id:, event:, payload:, resource_id:, resource_type:)
    raise NotImplementedError
  end

def mark_processing(provider_event_id)
        raise NotImplementedError
      end

      def mark_processed(provider_event_id)
        raise NotImplementedError
      end

      def mark_failed(provider_event_id, error_message)
        raise NotImplementedError
      end
end
end
