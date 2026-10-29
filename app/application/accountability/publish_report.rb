module Accountability
  # Publicar é ato da instituição, depois do aval da plataforma. A checagem de
  # instituição ativa fecha a porta para um relatório aprovado de tenant que foi
  # bloqueado depois da revisão.
  class PublishReport
    def initialize(institution_repository:, accountability_report_repository:)
      @institution_repository = institution_repository
      @accountability_report_repository = accountability_report_repository
    end

    def call(report_id:, institution_id:, at:)
      institution = @institution_repository.find(institution_id)
      unless institution&.active?
        raise InvalidAccountabilityReport, "institution must be active to publish a report"
      end

      report = @accountability_report_repository.find_for_institution(
        id: report_id,
        institution_id: institution_id
      )
      return nil if report.nil?

      report.publish!(at: at)
      @accountability_report_repository.save(report)
    end
  end
end
