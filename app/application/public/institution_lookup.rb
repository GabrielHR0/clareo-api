module Public
  # A porta de entrada do site público é o slug. Instituição sem slug, inativa
  # ou inexistente não tem perfil público: não existe "quase público".
  module InstitutionLookup
    private

    def find_public_institution(slug)
      institution = @institution_repository.find_by_slug(slug)
      return nil if institution.nil?
      return nil unless institution.public_profile_ready?

      institution
    end
  end
end
