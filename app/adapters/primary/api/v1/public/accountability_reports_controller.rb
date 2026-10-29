module Api
  module V1
    module Public
      class AccountabilityReportsController < BaseController
        def index
          result = published_reports.call(
            slug: params[:slug],
            campaign_id: params[:campaign_id].presence&.to_i,
            limit: limit_param,
            offset: offset_param
          )
          return render_not_found("Instituição não encontrada") if result.nil?

          render json: {
            institution: Serializers::InstitutionSerializer.call(result[:institution]),
            accountability_reports: result[:reports].map do |report|
              Serializers::AccountabilityReportSerializer.call(report, include_entries: false)
            end
          }
        end

        def show
          result = published_report.call(params[:id])
          return render_not_found("Prestação de contas não encontrada") if result.nil?

          render json: {
            institution: Serializers::InstitutionSerializer.call(result[:institution]),
            accountability_report: Serializers::AccountabilityReportSerializer.call(
              result[:report],
              documents_by_ledger_entry: result[:documents_by_ledger_entry]
            )
          }
        end

        private

        def published_reports
          @published_reports ||= ::Public::PublishedReports.new(
            institution_repository: institution_repository,
            accountability_report_repository: accountability_report_repository
          )
        end

        def published_report
          @published_report ||= ::Public::PublishedReport.new(
            institution_repository: institution_repository,
            accountability_report_repository: accountability_report_repository,
            document_repository: document_repository
          )
        end
      end
    end
  end
end
