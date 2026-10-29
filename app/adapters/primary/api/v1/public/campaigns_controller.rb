module Api
  module V1
    module Public
      class CampaignsController < BaseController
        def show
          result = campaign_page.call(slug: params[:slug], campaign_id: params[:id])
          return render_not_found("Campanha não encontrada") if result.nil?

          render json: {
            institution: Serializers::InstitutionSerializer.call(result[:institution]),
            campaign: Serializers::CampaignSerializer.call(result[:campaign]),
            summary: Serializers::FinancialSummarySerializer.call(result[:summary]),
            accountability_reports: result[:reports].map do |report|
              Serializers::AccountabilityReportSerializer.call(report, include_entries: false)
            end
          }
        end

        private

        def campaign_page
          @campaign_page ||= ::Public::CampaignPage.new(
            institution_repository: institution_repository,
            campaign_repository: campaign_repository,
            ledger_entry_repository: ledger_entry_repository,
            accountability_report_repository: accountability_report_repository
          )
        end
      end
    end
  end
end
