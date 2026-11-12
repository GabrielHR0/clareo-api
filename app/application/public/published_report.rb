module Public
  # O relatório público carrega o snapshot e só os comprovantes que a
  # instituição marcou como públicos. Documento privado não vaza por estar
  # ligado a um lançamento que aparece no relatório.
  class PublishedReport
    def initialize(institution_repository:, accountability_report_repository:,
                   document_repository:)
      @institution_repository = institution_repository
      @accountability_report_repository = accountability_report_repository
      @document_repository = document_repository
    end

    def call(report_id)
      report = @accountability_report_repository.find_published(report_id)
      return nil if report.nil?

      institution = @institution_repository.find(report.institution_id)
      return nil unless institution&.public_profile_ready?

      documents = @document_repository.list_public_for_ledger_entries(
        institution_id: institution.id,
        ledger_entry_ids: report.entries.map(&:ledger_entry_id)
      )

      {
        institution: institution,
        report: report,
        documents_by_ledger_entry: documents.group_by(&:attachable_id)
      }
    end
  end
end
