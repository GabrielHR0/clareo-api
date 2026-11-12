module Public
  # Catálogo das campanhas visíveis no site público. A descoberta é por
  # instituição pública, nunca por campanha órfã: campanha de tenant sem slug
  # não aparece, mesmo que o status esteja ativo.
  class CampaignCatalog
    def initialize(institution_repository:, campaign_repository:,
                   ledger_entry_repository:)
      @institution_repository = institution_repository
      @campaign_repository = campaign_repository
      @ledger_entry_repository = ledger_entry_repository
    end

    def call(limit: nil, offset: nil)
      institutions = @institution_repository.list_public
      institutions_by_id = institutions.to_h { |institution| [ institution.id, institution ] }

      campaigns = @campaign_repository.list_public(
        institution_ids: institutions_by_id.keys,
        limit: limit,
        offset: offset
      )

      campaigns.filter_map do |campaign|
        institution = institutions_by_id[campaign.institution_id]
        next if institution.nil?

        {
          institution: institution,
          campaign: campaign,
          summary: @ledger_entry_repository.financial_summary(
            institution.id,
            from: campaign.starts_on,
            to: campaign.ends_on,
            campaign_id: campaign.id
          )
        }
      end
    end
  end
end
