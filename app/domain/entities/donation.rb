class Donation
  PAYMENT_METHODS = %i[pix boleto credit_card].freeze
  STATUSES = %i[pending received refunded cancelled rejected split_blocked].freeze
  FINAL_STATUSES = %i[refunded cancelled rejected].freeze

  attr_reader :id, :institution, :donor_name, :donor_email, :amount,
              :payment_method, :reference, :splits, :status, :net_amount,
              :asaas_payment_id, :received_at, :refunded_at

  def initialize(institution:, donor_name:, amount:, payment_method:,
                 reference:, splits:, id: nil, donor_email: nil, status: :pending,
                 net_amount: nil, asaas_payment_id: nil, received_at: nil,
                 refunded_at: nil)
    @id = id
    @institution = institution
    @donor_name = donor_name
    @donor_email = donor_email
    @amount = Money.build(amount)
    @payment_method = payment_method
    @reference = ExternalReference.build(reference)
    @splits = splits
    @status = status
    @net_amount = net_amount.nil? ? nil : Money.build(net_amount)
    @asaas_payment_id = asaas_payment_id
    @received_at = received_at
    @refunded_at = refunded_at

    validate!
  end

  def institution_split
    splits.find { |split| split.recipient == :institution }
  end

  def platform_split
    splits.find { |split| split.recipient == :platform }
  end

  # Only what the provider actually routes by split. The platform share stays
  # on the issuing account and is never sent.
  def routable_splits
    splits.select(&:routable?)
  end

  # The only path to a confirmed donation. Creating the charge proves nothing:
  # the provider answers PENDING and payment may never arrive.
  def confirm_receipt!(asaas_payment_id:, net_amount:, at:)
    transition_to!(%i[pending split_blocked], :received)
    @asaas_payment_id = asaas_payment_id
    @net_amount = Money.build(net_amount)
    @received_at = at
    self
  end

  def refund!(at: nil)
    transition_to!(%i[received], :refunded)
    @refunded_at = at
    self
  end

  def reject!
    transition_to!(%i[pending], :rejected)
    self
  end

  def cancel!
    transition_to!(%i[pending split_blocked], :cancelled)
    self
  end

  def block_split!
    transition_to!(%i[pending received], :split_blocked)
    self
  end

  def unblock_split!
    transition_to!(%i[split_blocked], :pending)
    self
  end

  def pending?
    status == :pending
  end

  def received?
    status == :received
  end

  def refunded?
    status == :refunded
  end

  def split_blocked?
    status == :split_blocked
  end

  def final?
    FINAL_STATUSES.include?(status)
  end

  private

  def validate!
    validate_payment_method!
    validate_amount!
    validate_institution!
    validate_splits!
    validate_status!
  end

  def validate_payment_method!
    return if PAYMENT_METHODS.include?(payment_method)

    raise InvalidDonation, "payment method must be one of #{PAYMENT_METHODS.join(', ')}"
  end

  def validate_amount!
    raise InvalidDonation, "amount must be positive" unless amount.positive?
  end

  def validate_institution!
    raise InvalidDonation, "institution is required" if institution.nil?
    raise InvalidDonation, "institution cannot accept donations" unless institution.accepts_donations?
  end

  def validate_splits!
    raise InvalidDonation, "splits cannot be empty" if splits.nil? || splits.empty?

    total = Percentage.sum(splits.map(&:percentage))
    unless total == Percentage.build(100)
      raise InvalidDonation, "splits must total exactly 100%, got #{total}%"
    end

    return if institution_split

    raise InvalidDonation, "at least one institution split is required"
  end

  def validate_status!
    raise InvalidDonation, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidDonation, "cannot move donation from #{status} to #{target}"
    end

    @status = target
  end
end
