module Repositories
# A campanha guarda a meta e o período, nunca o valor arrecadado: os dois são
# derivados dos lançamentos, porque cache dessincroniza no primeiro split
# estornado e a campanha passa a anunciar um número que não existe.
class CampaignRepository
  # @return [Campaign, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Array<Campaign>] o feed público: só as ativas
  def list_in_feed(institution_id)
    raise NotImplementedError
  end

  # @return [Array<Campaign>]
  def list_by_institution(institution_id, status: nil)
    raise NotImplementedError
  end

  def save(campaign)
    raise NotImplementedError
  end
end
end
