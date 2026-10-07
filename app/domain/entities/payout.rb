class Payout
  STATUSES = %i[pending processing completed failed cancelled].freeze

  attr_reader :id, :institution, :donation, :amount, :pix_key,
              :provider_transfer_id, :status, :failure_reason, :completed_at

  def initialize(institution:, amount:, pix_key:, id: nil, donation: nil,
                 provider_transfer_id: nil, status: :pending,
                 failure_reason: nil, completed_at: nil)
    @id = id
    @institution = institution
    @donation = donation
    @amount = Money.build(amount)
    @pix_key = PixKey.build(pix_key)
    @provider_transfer_id = provider_transfer_id
    @status = status
    @failure_reason = failure_reason
    @completed_at = completed_at

    validate!
  end

  def start_processing!(provider_transfer_id:)
    transition_to!(%i[pending], :processing)
    @provider_transfer_id = provider_transfer_id
    self
  end

  def complete!(at: nil)
    transition_to!(%i[pending processing], :completed)
    @completed_at = at
    self
  end

  def fail!(reason: nil)
    transition_to!(%i[pending processing], :failed)
    @failure_reason = reason
    self
  end

  def cancel!
    transition_to!(%i[pending processing], :cancelled)
    self
  end

  def completed?
    status == :completed
  end

  def failed?
    status == :failed
  end

  def pending?
    status == :pending
  end

  private

  def validate!
    raise InvalidDonation, "payout institution is required" if institution.nil?
    raise InvalidDonation, "payout amount must be positive" unless amount.positive?
    raise InvalidDonation, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidDonation, "cannot move payout from #{status} to #{target}"
    end

    @status = target
  end
end
