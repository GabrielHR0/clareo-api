module Repositories
# O documento é polimórfico: serve de lastro para um lançamento contábil e para
# um post do feed. O repositório não carrega os anexos por padrão, porque listar
# a feed de um institution não deve baixar binário.
class DocumentRepository
  # @return [Document, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Array<Document>]
  def list_for_attachable(institution_id:, attachable_type:, attachable_id:)
    raise NotImplementedError
  end

  # @return [Array<Document>] filtra por tenant, para a listagem pública
  def list_by_institution(institution_id)
    raise NotImplementedError
  end

  # @return [Array<Document>] só os documentos que a instituição optou por expor
  def list_public_for_attachable(institution_id:, attachable_type:, attachable_id:)
    raise NotImplementedError
  end

  # @return [Array<Document>] anexos públicos do lançamento, em lote
  def list_public_for_ledger_entries(institution_id:, ledger_entry_ids:)
    raise NotImplementedError
  end

  def save(document)
    raise NotImplementedError
  end
end
end
