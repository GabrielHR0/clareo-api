module Accountability
  # A revisão é da plataforma. Cada ação persiste imediatamente: um parecer
  # aprovado que fica só em memória é um relatório que pode ser publicado sem
  # ter passado pela revisão.
  class ReviewReport
    def initialize(accountability_report_repository:)
      @accountability_report_repository = accountability_report_repository
    end

    def start!(report_id:, reviewer_id:, at:)
      report = @accountability_report_repository.find(report_id)
      return nil if report.nil?

      report.start_review!(reviewer_id: reviewer_id, at: at)
      @accountability_report_repository.save(report)
    end

    def approve!(report_id:, reviewer_id:, opinion:, at:)
      report = @accountability_report_repository.find(report_id)
      return nil if report.nil?

      report.approve!(reviewer_id: reviewer_id, opinion: opinion, at: at)
      @accountability_report_repository.save(report)
    end

    def request_changes!(report_id:, reviewer_id:, notes:, at:)
      report = @accountability_report_repository.find(report_id)
      return nil if report.nil?

      report.request_changes!(reviewer_id: reviewer_id, notes: notes, at: at)
      @accountability_report_repository.save(report)
    end
  end
end
