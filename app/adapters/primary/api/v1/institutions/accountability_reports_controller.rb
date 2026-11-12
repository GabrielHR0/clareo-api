module Api
  module V1
    module Institutions
      class AccountabilityReportsController < BaseController
        before_action :load_institution
        before_action :authorize_current_institution!

        def index
          reports = accountability_report_repository.list_by_institution(
            @institution.id,
            status: params[:status].presence
          )

          render json: {
            institution: Serializers::InstitutionSerializer.call(@institution),
            accountability_reports: reports.map do |report|
              Serializers::AccountabilityReportSerializer.call(report, include_entries: false)
            end
          }
        end

        def show
          report = accountability_report_repository.find_for_institution(
            id: params[:id],
            institution_id: @institution.id
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def create
          report = build_report.call(
            institution_id: @institution.id,
            title: params.require(:title),
            summary: params[:summary],
            period_start: date_param(:period_start),
            period_end: date_param(:period_end),
            campaign_id: params[:campaign_id].presence&.to_i
          )

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }, status: :created
        end

        def update
          report = update_report.call(
            report_id: params[:id],
            institution_id: @institution.id,
            title: params.require(:title),
            summary: params[:summary],
            period_start: date_param(:period_start),
            period_end: date_param(:period_end),
            campaign_id: params[:campaign_id].presence&.to_i
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def submit
          report = submit_report.call(
            report_id: params[:id],
            institution_id: @institution.id,
            at: Time.current
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        def publish
          report = publish_report.call(
            report_id: params[:id],
            institution_id: @institution.id,
            at: Time.current
          )
          return render_not_found("Prestação de contas não encontrada") if report.nil?

          render json: {
            accountability_report: Serializers::AccountabilityReportSerializer.call(report)
          }
        end

        private

        def load_institution
          @institution = institution_repository.find(params[:institution_id])
          render_not_found("Instituição não encontrada") if @institution.nil?
        end

        def authorize_current_institution!
          authorize_institution!(@institution) if @institution
        end
      end
    end
  end
end
