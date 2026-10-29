module Public
  class InstitutionFeed
    include InstitutionLookup

    def initialize(institution_repository:, post_repository:)
      @institution_repository = institution_repository
      @post_repository = post_repository
    end

    def call(slug:, campaign_id: nil, limit: nil, offset: nil)
      institution = find_public_institution(slug)
      return nil if institution.nil?

      {
        institution: institution,
        posts: @post_repository.list_feed(
          institution.id,
          campaign_id: campaign_id,
          limit: limit,
          offset: offset
        )
      }
    end
  end
end
