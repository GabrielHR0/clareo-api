module Persistence
  # Implementa Repositories::CostCenterRepository.
  class CostCenterRepository
    def find(institution_id:, code:)
      record = CostCenterRecord.find_by(institution_id: institution_id, code: code.to_s)
      record && RecordMapper.record_to_cost_center(record)
    end

    def list_by_institution(institution_id)
      CostCenterRecord.where(institution_id: institution_id).order(:code).map do |record|
        RecordMapper.record_to_cost_center(record)
      end
    end

    def list_active(institution_id)
      CostCenterRecord.active.where(institution_id: institution_id).order(:code).map do |record|
        RecordMapper.record_to_cost_center(record)
      end
    end

    def save(cost_center)
      record = CostCenterRecord.find_or_initialize_by(
        institution_id: cost_center.institution_id,
        code: cost_center.code
      )
      RecordMapper.cost_center_to_record(cost_center, record)
      record.save!
      RecordMapper.record_to_cost_center(record)
    end
  end
end
