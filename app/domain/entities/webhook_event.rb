class WebhookEvent
  STATUSES = %i[received processing processed failed].freeze

  attr_reader :provider_event_id, :event, :payload, :resource_type, :resource_id,
              :status, :attempts, :processed_at, :error_message

  def initialize(provider_event_id:, event:, payload:, resource_type:, resource_id:,
                 status: :received, attempts: 0, processed_at: nil, error_message: nil)
    @provider_event_id = provider_event_id
    @event = event
    @payload = payload
    @resource_type = resource_type
    @resource_id = resource_id
    @status = status
    @attempts = attempts
    @processed_at = processed_at
    @error_message = error_message

    validate!
  end

  def start_processing!
    unless %i[received failed].include?(status)
      raise InvalidDonation, "cannot move webhook from #{status} to processing"
    end

    @status = :processing
    @attempts += 1
    self
  end

  def processed!(at: nil)
    unless %i[processing].include?(status)
      raise InvalidDonation, "cannot move webhook from #{status} to processed"
    end

    @status = :processed
    @processed_at = at
    self
  end

  def failed!(message:)
    unless %i[processing].include?(status)
      raise InvalidDonation, "cannot move webhook from #{status} to failed"
    end

    @status = :failed
    @error_message = message
    self
  end

  # The effect may already have been applied, so the business logic must check
  # the current entity state before acting again.
  def already_processed?
    status == :processed
  end

  def processing?
    status == :processing
  end

  def processed?
    status == :processed
  end

  def failed?
    status == :failed
  end

  def received?
    status == :received
  end

  private

  def validate!
    if provider_event_id.to_s.strip.empty?
      raise InvalidDonation, "provider event id is required"
    end
    raise InvalidDonation, "event name is required" if event.to_s.strip.empty?
    raise InvalidDonation, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end
end
