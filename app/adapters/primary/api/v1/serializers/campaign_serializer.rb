module Api
  module V1
    module Serializers
      class CampaignSerializer
        def self.call(campaign)
          {
            id: campaign.id,
            institution_id: campaign.institution_id,
            title: campaign.title,
            description: campaign.description,
            goal_brl: campaign.goal.to_s,
            starts_on: campaign.starts_on&.iso8601,
            ends_on: campaign.ends_on&.iso8601,
            status: campaign.status.to_s
          }
        end
      end
    end
  end
end
