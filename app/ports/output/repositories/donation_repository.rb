module Repositories
class DonationRepository
  # @return [Donation, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Donation, nil]
  def find_by_reference(reference)
    raise NotImplementedError
  end

  # @return [Donation, nil]
  def find_by_provider_payment_id(provider_payment_id)
    raise NotImplementedError
  end

  # @return [Array<Donation>]
  def list_by_institution(institution_id, status: nil)
    raise NotImplementedError
  end

  def save(donation)
    raise NotImplementedError
  end
end
end
