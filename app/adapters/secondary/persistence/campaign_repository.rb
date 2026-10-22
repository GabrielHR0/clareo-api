module Persistence
  # Implementa Repositories::CampaignRepository.
  class CampaignRepository
    def find(id)
      record = CampaignRecord.find_by(id: id)
      record && RecordMapper.record_to_campaign(record)
    end

    def list_in_feed(institution_id)
      CampaignRecord.in_feed.where(institution_id: institution_id).map do |record|
        RecordMapper.record_to_campaign(record)
      end
    end

    def list_by_institution(institution_id, status: nil)
      scope = CampaignRecord.where(institution_id: institution_id)
      scope = scope.where(status: status.to_s) if status
      scope.order(starts_on: :desc, id: :desc).map { |record| RecordMapper.record_to_campaign(record) }
    end

    def save(campaign)
      record = CampaignRecord.find_or_initialize_by(id: campaign.id)
      RecordMapper.campaign_to_record(campaign, record)
      record.save!
      RecordMapper.record_to_campaign(record)
    end
  end
end
