module Repositories
class CostCenterRepository
  # @return [CostCenter, nil]
  def find(institution_id:, code:)
    raise NotImplementedError
  end

  # @return [Array<CostCenter>]
  def list_by_institution(institution_id)
    raise NotImplementedError
  end

  def list_active(institution_id)
    raise NotImplementedError
  end

  def save(cost_center)
    raise NotImplementedError
  end
end
end
