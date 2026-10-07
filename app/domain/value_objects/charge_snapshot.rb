class ChargeSnapshot
  STATUSES = %i[pending confirmed received overdue refunded cancelled deleted].freeze

  attr_reader :provider_payment_id, :status, :gross_amount, :net_amount,
              :invoice_url, :bank_slip_url, :due_on

  def initialize(provider_payment_id:, status:, gross_amount:, net_amount: nil,
                 invoice_url: nil, bank_slip_url: nil, due_on: nil)
    @provider_payment_id = provider_payment_id
    @status = status
    @gross_amount = Money.build(gross_amount)
    @net_amount = net_amount.nil? ? nil : Money.build(net_amount)
    @invoice_url = invoice_url
    @bank_slip_url = bank_slip_url
    @due_on = due_on

    validate!
  end

  def paid?
    %i[confirmed received].include?(status)
  end

  private

  def validate!
    raise InvalidDonation, "charge id is required" if provider_payment_id.to_s.strip.empty?
    raise InvalidDonation, "charge status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end
end
