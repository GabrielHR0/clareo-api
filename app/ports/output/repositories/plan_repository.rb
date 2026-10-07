module Repositories
class PlanRepository
  # @return [Plan, nil]
  def find_by_code(code)
    raise NotImplementedError
  end

  # @return [Array<Plan>]
  def list
    raise NotImplementedError
  end
end
end
