module Api
  module V1
    module Public
      class InstitutionsController < BaseController
        def show
          result = profile_query.call(slug: params[:slug])
          return render_not_found("Instituição não encontrada") if result.nil?

          render json: {
            institution: Serializers::InstitutionSerializer.call(result[:institution]),
            summary: Serializers::FinancialSummarySerializer.call(result[:summary]),
            campaigns: result[:campaigns].map do |campaign|
              Serializers::CampaignSerializer.call(campaign)
            end
          }
        end

        def feed
          result = feed_query.call(
            slug: params[:slug],
            campaign_id: params[:campaign_id].presence&.to_i,
            limit: limit_param,
            offset: offset_param
          )
          return render_not_found("Instituição não encontrada") if result.nil?

          render json: {
            institution: Serializers::InstitutionSerializer.call(result[:institution]),
            posts: result[:posts].map { |post| Serializers::PostSerializer.call(post) }
          }
        end

        private

        def profile_query
          @profile_query ||= ::Public::InstitutionProfile.new(
            institution_repository: institution_repository,
            campaign_repository: campaign_repository,
            ledger_entry_repository: ledger_entry_repository
          )
        end

        def feed_query
          @feed_query ||= ::Public::InstitutionFeed.new(
            institution_repository: institution_repository,
            post_repository: post_repository
          )
        end
      end
    end
  end
end
