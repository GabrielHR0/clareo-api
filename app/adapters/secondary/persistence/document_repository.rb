module Persistence
  # Implementa Repositories::DocumentRepository.
  #
  # Não usa includes(:files): os anexos são blobs, e a listagem de documentos do
  # feed não deve carregar binário. Quem precisa do arquivo pede por id.
  class DocumentRepository
    def find(id)
      record = DocumentRecord.find_by(id: id)
      record && RecordMapper.record_to_document(record)
    end

    def list_for_attachable(institution_id:, attachable_type:, attachable_id:)
      scope = DocumentRecord.where(institution_id: institution_id)

      scope =
        case attachable_type
        when DocumentTarget::LEDGER_ENTRY then scope.where(ledger_entry_id: attachable_id)
        when DocumentTarget::POST then scope.where(post_id: attachable_id)
        else return []
        end

      scope.order(:issued_on, :id).map { |record| RecordMapper.record_to_document(record) }
    end

    def list_by_institution(institution_id)
      DocumentRecord.where(institution_id: institution_id).order(:issued_on, :id).map do |record|
        RecordMapper.record_to_document(record)
      end
    end

    def save(document)
      record = DocumentRecord.find_or_initialize_by(id: document.id)
      RecordMapper.document_to_record(document, record)
      record.save!
      RecordMapper.record_to_document(record)
    end
  end
end
