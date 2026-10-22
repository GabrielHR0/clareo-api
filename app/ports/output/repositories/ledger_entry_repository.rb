module Repositories
# O razão. A distinção que importa é origin: donation é fato do sistema,
# declared é declaração da instituição. A conferência de 9E compara as duas.
class LedgerEntryRepository
  # @return [LedgerEntry, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Array<LedgerEntry>] o extrato da instituição, do mais recente
  def list_by_institution(institution_id, status: nil)
    raise NotImplementedError
  end

  # @return [Array<LedgerEntry>] lançamentos de um período, por data de caixa
  def list_in_period(institution_id, from:, to:)
    raise NotImplementedError
  end

  # @return [Money] soma das receitas de sistema no período. É o que o sistema
  #   sabe que entrou, contra o que a instituição declarou.
  def declared_income_total(institution_id, from:, to:)
    raise NotImplementedError
  end

  def save(entry)
    raise NotImplementedError
  end

  # Cria a entrada de receita a partir de um split liquidado. Idempotente por
  # donation_split_id: o provedor entrega webhook em modo at least once, e o
  # índice único no banco é a rede contra a receita duplicada.
  def record_donation_income!(institution_id:, donation_split_id:, amount:,
                              account_id:, posted_on:, campaign_id: nil,
                              cost_center_id: nil, description: nil)
    raise NotImplementedError
  end
end
end
