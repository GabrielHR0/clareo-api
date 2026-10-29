module Public
  # A campanha pública é a meta mais o que o razão confirma. O progresso não é
  # coluna: é a mesma leitura que alimenta a prestação de contas.
  class CampaignPage
    include InstitutionLookup

    def initialize(institution_repository:, campaign_repository:,
                   ledger_entry_repository:, accountability_report_repository:)
      @institution_repository = institution_repository
      @campaign_repository = campaign_repository
      @ledger_entry_repository = ledger_entry_repository
      @accountability_report_repository = accountability_report_repository
    end

    def call(slug:, campaign_id:)
      institution = find_public_institution(slug)
      return nil if institution.nil?

      campaign = @campaign_repository.find(campaign_id)
      return nil if campaign.nil?
      return nil unless campaign.institution_id == institution.id
      return nil if campaign.paused?

      {
        institution: institution,
        campaign: campaign,
        summary: @ledger_entry_repository.financial_summary(
          institution.id,
          from: campaign.starts_on,
          to: campaign.ends_on,
          campaign_id: campaign.id
        ),
        reports: @accountability_report_repository.list_published(
          institution.id,
          campaign_id: campaign.id
        )
      }
    end
  end
end
