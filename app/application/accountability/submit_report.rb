module Accountability
  # O submit refaz o snapshot. Se um lançamento entrou depois do rascunho, ele
  # entra agora; se foi estornado, sai. A declaração é o que está no razão no
  # momento em que a instituição aperta o botão.
  class SubmitReport
    def initialize(accountability_report_repository:, snapshot_entries:)
      @accountability_report_repository = accountability_report_repository
      @snapshot_entries = snapshot_entries
    end

    def call(report_id:, institution_id:, at:)
      report = @accountability_report_repository.find_for_institution(
        id: report_id,
        institution_id: institution_id
      )
      return nil if report.nil?

      entries = @snapshot_entries.call(
        institution_id: report.institution_id,
        period_start: report.period_start,
        period_end: report.period_end,
        campaign_id: report.campaign_id
      )

      report.submit!(entries: entries, at: at)
      @accountability_report_repository.save(report, sync_entries: true)
    end
  end
end
