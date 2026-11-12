module Repositories
class InstitutionRepository
  # @return [Institution, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Institution, nil]
  def find_by_cnpj(cnpj)
    raise NotImplementedError
  end

  # @return [Institution, nil] perfil público, buscado pelo slug estável
  def find_by_slug(slug)
    raise NotImplementedError
  end

  # @return [Array<Institution>] instituições com perfil público disponível
  def list_public
    raise NotImplementedError
  end

  # @return [Array<Institution>]
  def list_by_user(user_id)
    raise NotImplementedError
  end

  def count_by_user(user_id)
    raise NotImplementedError
  end

  def save(institution)
    raise NotImplementedError
  end
end
end
