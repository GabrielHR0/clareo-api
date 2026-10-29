module Api
  module V1
    class BaseController < ApplicationController
      rescue_from DomainError do |error|
        render json: {
          error: error.message,
          code: error.code || error.class.name.underscore
        }, status: :unprocessable_content
      end

      rescue_from ActionController::ParameterMissing do |error|
        render json: { error: error.message, code: "parameter_missing" },
          status: :bad_request
      end

      rescue_from ActionController::BadRequest do |error|
        render json: { error: error.message, code: "bad_request" },
          status: :bad_request
      end

      private

      def render_not_found(message = "Não encontrado")
        render json: { error: message, code: "not_found" }, status: :not_found
      end

      def limit_param
        positive_integer(params[:limit])
      end

      def offset_param
        positive_integer(params[:offset]) || 0
      end

      def positive_integer(value)
        return nil if value.blank?

        number = Integer(value, exception: false)
        number if number&.positive?
      end

      def institution_repository
        @institution_repository ||= Persistence::InstitutionRepository.new
      end

      def campaign_repository
        @campaign_repository ||= Persistence::CampaignRepository.new
      end

      def post_repository
        @post_repository ||= Persistence::PostRepository.new
      end

      def document_repository
        @document_repository ||= Persistence::DocumentRepository.new
      end

      def account_repository
        @account_repository ||= Persistence::AccountRepository.new
      end

      def ledger_entry_repository
        @ledger_entry_repository ||= Persistence::LedgerEntryRepository.new
      end

      def accountability_report_repository
        @accountability_report_repository ||= Persistence::AccountabilityReportRepository.new
      end

      def snapshot_entries
        @snapshot_entries ||= Accountability::SnapshotEntries.new(
          ledger_entry_repository: ledger_entry_repository,
          account_repository: account_repository
        )
      end

      def build_report
        @build_report ||= Accountability::BuildReport.new(
          institution_repository: institution_repository,
          campaign_repository: campaign_repository,
          snapshot_entries: snapshot_entries,
          accountability_report_repository: accountability_report_repository
        )
      end

      def update_report
        @update_report ||= Accountability::UpdateReport.new(
          institution_repository: institution_repository,
          campaign_repository: campaign_repository,
          snapshot_entries: snapshot_entries,
          accountability_report_repository: accountability_report_repository
        )
      end

      def submit_report
        @submit_report ||= Accountability::SubmitReport.new(
          accountability_report_repository: accountability_report_repository,
          snapshot_entries: snapshot_entries
        )
      end

      def publish_report
        @publish_report ||= Accountability::PublishReport.new(
          institution_repository: institution_repository,
          accountability_report_repository: accountability_report_repository
        )
      end

      def review_report
        @review_report ||= Accountability::ReviewReport.new(
          accountability_report_repository: accountability_report_repository
        )
      end

      def date_param(name)
        Date.iso8601(params.require(name).to_s)
      rescue Date::Error
        raise ActionController::BadRequest, "#{name} must be an ISO 8601 date"
      end
    end
  end
end
