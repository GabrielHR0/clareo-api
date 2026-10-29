module Api
  module V1
    module Admin
      class AccountabilityReportsController < BaseController
        before_action :require_platform_admin!

        def index
          reports = accountability_report_repository.list_pending(
            limit: limit_param,
            offset: offset_param
          )

          render json: {
            accountability_reports: reports.map do |report|
              Serializers::AccountabilityReportSerializer.call(report, include_entries: false)
            end
          }
        end

        def show
          report = accountability_report_repository.find(params[:id])
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def start_review
          report = review_report.start!(
            report_id: params[:id],
            reviewer_id: current_user.id,
            at: Time.current
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def approve
          report = review_report.approve!(
            report_id: params[:id],
            reviewer_id: current_user.id,
            opinion: params.require(:opinion),
            at: Time.current
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def request_changes
          report = review_report.request_changes!(
            report_id: params[:id],
            reviewer_id: current_user.id,
            notes: params.require(:notes),
            at: Time.current
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end
      end
    end
  end
end
