class DonationSplit
  RECIPIENTS = %i[institution platform].freeze
  STATUSES = %i[pending done cancelled blocked].freeze
  CANCELLATION_REASONS = %i[
    checkout_validation_failed
    external_authorization_refused
    manual_cancellation
    payment_deleted
    payment_overdue
    payment_received_in_cash
    payment_refunded
    value_divergence_block
    wallet_unable_to_receive
  ].freeze

  attr_reader :recipient, :percentage, :institution, :status,
              :total_value, :asaas_split_id, :cancellation_reason

  class << self
    def for_institution(institution:, percentage:)
      new(recipient: :institution, percentage: percentage, institution: institution)
    end

    def for_platform(percentage:)
      new(recipient: :platform, percentage: percentage)
    end
  end

  def initialize(recipient:, percentage:, institution: nil, status: :pending,
                 total_value: nil, asaas_split_id: nil, cancellation_reason: nil)
    @recipient = recipient
    @percentage = Percentage.build(percentage)
    @institution = institution
    @status = status
    @total_value = total_value.nil? ? nil : Money.build(total_value)
    @asaas_split_id = asaas_split_id
    @cancellation_reason = cancellation_reason

    validate!
  end

  # The platform share is never sent to the provider: the issuing account keeps
  # whatever is not routed by the split. Modelling it explicitly keeps the
  # domain total (100%) and auditable while the adapter omits it.
  def routable?
    recipient == :institution
  end

  # What this party is entitled to out of the net amount. Only knowable after
  # the provider reports the net amount.
  def entitlement_of(net_amount)
    Money.build(net_amount).percentage_of(percentage)
  end

  def mark_done!(total_value:, asaas_split_id: nil)
    @status = :done
    @total_value = Money.build(total_value)
    @asaas_split_id = asaas_split_id
    self
  end

  def cancel!(reason: :manual_cancellation)
    @status = :cancelled
    @cancellation_reason = reason
    self
  end

  def block!
    @status = :blocked
    @cancellation_reason = :value_divergence_block
    self
  end

  def done?
    status == :done
  end

  def cancelled?
    status == :cancelled
  end

  def blocked?
    status == :blocked
  end

  private

  def validate!
    unless RECIPIENTS.include?(recipient)
      raise InvalidSplit, "recipient must be one of #{RECIPIENTS.join(', ')}"
    end
    unless STATUSES.include?(status)
      raise InvalidSplit, "status must be one of #{STATUSES.join(', ')}"
    end
    if percentage.zero?
      raise InvalidSplit, "percentage cannot be zero"
    end

    validate_recipient!
  end

  def validate_recipient!
    if recipient == :institution && institution.nil?
      raise InvalidSplit, "institution split requires an institution"
    end
    if recipient == :platform && institution
      raise InvalidSplit, "platform split stays on the issuing account and cannot have an institution"
    end
  end
end
