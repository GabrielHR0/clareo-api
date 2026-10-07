class PaymentGateway
  # Creates the charge on the issuing account. The returned snapshot is
  # never proof of payment: the provider answers with a pending status and
  # the donation only becomes received through the payment webhook.
  #
  # @param splits [Array<DonationSplit>] only routable splits are sent; the
  #   platform share stays on the issuing account and must be omitted
  # @return [ChargeSnapshot]
  def create_charge(customer_id:, amount:, payment_method:, due_on:,
                   reference:, splits: [])
    raise NotImplementedError
  end

  # Canonical source of truth. Always query before trusting webhook payload.
  #
  # @return [ChargeSnapshot, nil]
  def find_charge(provider_payment_id)
    raise NotImplementedError
  end

  # @return [ChargeSnapshot]
  def refund_charge(provider_payment_id:, amount: nil)
    raise NotImplementedError
  end
end
