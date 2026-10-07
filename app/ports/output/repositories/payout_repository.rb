module Repositories
class PayoutRepository
  # @return [Payout, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Array<Payout>]
  def list_by_institution(institution_id, status: nil)
    raise NotImplementedError
  end

  # What an institution is owed but has not been paid yet, on the
  # pix_payout path where the platform holds the funds.
  def pending_amount_for(institution_id)
    raise NotImplementedError
  end

  def save(payout)
    raise NotImplementedError
  end
end
end
