module Persistence
  # Implementa Repositories::PlanRepository.
  class PlanRepository
    def find_by_code(code)
      record = PlanRecord.find_by(code: code.to_s)
      record && RecordMapper.record_to_plan(record)
    end

    def list
      PlanRecord.order(:price_brl).map { |record| RecordMapper.record_to_plan(record) }
    end

    def save(plan)
      record = PlanRecord.find_by(code: plan.code.to_s) || PlanRecord.new
      RecordMapper.plan_to_record(plan, record)
      record.save!
      RecordMapper.record_to_plan(record)
    end
  end
end
