class TransferSnapshot
  STATUSES = %i[created pending in_bank_processing blocked done failed cancelled].freeze

  attr_reader :provider_transfer_id, :status, :amount, :failure_reason

  def initialize(provider_transfer_id:, status:, amount:, failure_reason: nil)
    @provider_transfer_id = provider_transfer_id
    @status = status
    @amount = Money.build(amount)
    @failure_reason = failure_reason

    validate!
  end

  def settled?
    status == :done
  end

  def failed?
    status == :failed
  end

  def awaiting?
    %i[created pending in_bank_processing blocked].include?(status)
  end

  private

  def validate!
    raise InvalidDonation, "transfer id is required" if provider_transfer_id.to_s.strip.empty?
    raise InvalidDonation, "transfer status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
    raise InvalidDonation, "transfer amount must be positive" unless amount.positive?
  end
end
