module Public
  class PublishedReports
    include InstitutionLookup

    def initialize(institution_repository:, accountability_report_repository:)
      @institution_repository = institution_repository
      @accountability_report_repository = accountability_report_repository
    end

    def call(slug:, campaign_id: nil, limit: nil, offset: nil)
      institution = find_public_institution(slug)
      return nil if institution.nil?

      {
        institution: institution,
        reports: @accountability_report_repository.list_published(
          institution.id,
          campaign_id: campaign_id,
          limit: limit,
          offset: offset
        )
      }
    end
  end
end
