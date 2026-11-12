module Repositories
# A prestação de contas é um agregado com snapshot. O repositório grava o
# cabeçalho e as entradas na mesma transação, porque um relatório publicado sem
# as linhas que o sustentam seria um número sem lastro.
class AccountabilityReportRepository
  # @return [AccountabilityReport, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [AccountabilityReport, nil]
  def find_for_institution(id:, institution_id:)
    raise NotImplementedError
  end

  # @return [AccountabilityReport, nil] só relatórios já publicados
  def find_published(id)
    raise NotImplementedError
  end

  # @return [Array<AccountabilityReport>] todos os estados, para o admin
  def list_by_institution(institution_id, status: nil)
    raise NotImplementedError
  end

  # @return [Array<AccountabilityReport>] o que a instituição já publicou
  def list_published(institution_id, campaign_id: nil, limit: nil, offset: nil)
    raise NotImplementedError
  end

  # @return [Array<AccountabilityReport>] fila de revisão da plataforma
  def list_pending(limit: nil, offset: nil)
    raise NotImplementedError
  end

  # sync_entries troca o snapshot inteiro. Só deve ser true enquanto o relatório
  # é editável ou no submit, nunca depois de publicado.
  def save(report, sync_entries: false)
    raise NotImplementedError
  end
end
end
