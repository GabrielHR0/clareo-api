module Public
  # Retrato do perfil: identidade, campanhas visíveis e o resumo financeiro.
  # Pausada não aparece; fechada continua porque o histórico da campanha é
  # prestação de contas, não promoção.
  class InstitutionProfile
    include InstitutionLookup

    def initialize(institution_repository:, campaign_repository:, ledger_entry_repository:)
      @institution_repository = institution_repository
      @campaign_repository = campaign_repository
      @ledger_entry_repository = ledger_entry_repository
    end

    def call(slug:)
      institution = find_public_institution(slug)
      return nil if institution.nil?

      campaigns = @campaign_repository
        .list_by_institution(institution.id)
        .reject(&:paused?)

      {
        institution: institution,
        campaigns: campaigns,
        summary: @ledger_entry_repository.financial_summary(institution.id)
      }
    end
  end
end
