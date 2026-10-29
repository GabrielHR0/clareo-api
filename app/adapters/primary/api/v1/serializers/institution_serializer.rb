module Api
  module V1
    module Serializers
      class InstitutionSerializer
        def self.call(institution)
          {
            id: institution.id,
            legal_name: institution.legal_name,
            trade_name: institution.trade_name,
            slug: institution.slug,
            description: institution.description,
            status: institution.status.to_s,
            accepts_donations: institution.accepts_donations?,
            withdraws_on_its_own: institution.withdraws_on_its_own?
          }
        end
      end
    end
  end
end
