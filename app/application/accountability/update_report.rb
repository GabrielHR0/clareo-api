module Accountability
  # Edita cabeçalho e período de um relatório ainda editável. O snapshot é
  # refeito porque o período pode ter mudado; o submit refará de novo, e é ele
  # que congela a declaração final.
  class UpdateReport
    def initialize(institution_repository:, campaign_repository:, snapshot_entries:,
                   accountability_report_repository:)
      @institution_repository = institution_repository
      @campaign_repository = campaign_repository
      @snapshot_entries = snapshot_entries
      @accountability_report_repository = accountability_report_repository
    end

    def call(report_id:, institution_id:, title:, summary:, period_start:,
             period_end:, campaign_id: nil)
      institution = @institution_repository.find(institution_id)
      unless institution&.active?
        raise InvalidAccountabilityReport, "institution must be active to edit a report"
      end

      report = @accountability_report_repository.find_for_institution(
        id: report_id,
        institution_id: institution_id
      )
      return nil if report.nil?

      validate_campaign!(campaign_id, institution_id)

      entries = @snapshot_entries.call(
        institution_id: institution_id,
        period_start: period_start,
        period_end: period_end,
        campaign_id: campaign_id
      )

      report.update_details!(
        title: title,
        summary: summary,
        period_start: period_start,
        period_end: period_end,
        campaign_id: campaign_id,
        entries: entries
      )
      @accountability_report_repository.save(report, sync_entries: true)
    end

    private

      def validate_campaign!(campaign_id, institution_id)
        return if campaign_id.nil?

        campaign = @campaign_repository.find(campaign_id)
        return if campaign&.institution_id == institution_id

        raise InvalidAccountabilityReport, "campaign does not belong to the institution"
      end
  end
end
