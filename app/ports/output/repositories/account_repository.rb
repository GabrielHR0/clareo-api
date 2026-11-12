module Repositories
# O plano de contas é do tenant: não existe catálogo global no banco, o
# catálogo padrão é semeado na instituição. Por isso toda leitura é filtrada
# por institution_id, e o código só é único dentro dela.
class AccountRepository
  # @return [Account, nil]
  def find(institution_id:, code:)
    raise NotImplementedError
  end

  # @return [Account, nil] busca pelo id, sempre limitada ao tenant
  def find_by_id(institution_id:, id:)
    raise NotImplementedError
  end

  # @return [Array<Account>] busca em lote, para montar snapshots sem N+1
  def find_by_ids(institution_id:, ids:)
    raise NotImplementedError
  end

  # @return [Array<Account>] todas as contas, ativas ou não
  def list_by_institution(institution_id)
    raise NotImplementedError
  end

  # @return [Array<Account>] só as ativas, que é o que o formulário offers
  def list_active(institution_id)
    raise NotImplementedError
  end

  # @return [Array<Account>] filtra por natureza, para o relatório por categoria
  def list_by_nature(institution_id, nature)
    raise NotImplementedError
  end

  def save(account)
    raise NotImplementedError
  end

  # Semeia o catálogo padrão da instituição. Idempotente por (institution, code):
  # rodar de novo não duplica nem sobrescreve customização, só completa o que
  # falta.
  def seed_template!(institution_id)
    raise NotImplementedError
  end
end
end
