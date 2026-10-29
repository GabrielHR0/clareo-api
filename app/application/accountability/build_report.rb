module Accountability
  # Monta o rascunho já com a fotografia do razão. O rascunho pode ser revisto
  # pela instituição; no submit a fotografia é refeita para não publicar número
  # que mudou entre a criação e o envio.
  class BuildReport
    def initialize(institution_repository:, campaign_repository:,
                   snapshot_entries:, accountability_report_repository:)
      @institution_repository = institution_repository
      @campaign_repository = campaign_repository
      @snapshot_entries = snapshot_entries
      @accountability_report_repository = accountability_report_repository
    end

    def call(institution_id:, title:, summary:, period_start:, period_end:,
             campaign_id: nil, save: true)
      institution = @institution_repository.find(institution_id)
      unless institution&.active?
        raise InvalidAccountabilityReport, "institution must be active to build a report"
      end

      validate_campaign!(campaign_id, institution_id)

      entries = @snapshot_entries.call(
        institution_id: institution_id,
        period_start: period_start,
        period_end: period_end,
        campaign_id: campaign_id
      )

      report = AccountabilityReport.build(
        institution_id: institution_id,
        campaign_id: campaign_id,
        title: title,
        summary: summary,
        period_start: period_start,
        period_end: period_end,
        entries: entries
      )

      return report unless save

      @accountability_report_repository.save(report, sync_entries: true)
    end

    private

      def validate_campaign!(campaign_id, institution_id)
        return if campaign_id.nil?

        campaign = @campaign_repository.find_for_institution(
          id: campaign_id,
          institution_id: institution_id
        )
        return if campaign

        raise InvalidAccountabilityReport, "campaign does not belong to the institution"
      end
  end
end
