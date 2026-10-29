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
      scope = scope_for_attachable(
        DocumentRecord.where(institution_id: institution_id),
        attachable_type: attachable_type,
        attachable_id: attachable_id
      )
      return [] if scope.nil?

      scope.order(:issued_on, :id).map { |record| RecordMapper.record_to_document(record) }
    end

    def list_by_institution(institution_id)
      DocumentRecord.where(institution_id: institution_id).order(:issued_on, :id).map do |record|
        RecordMapper.record_to_document(record)
      end
    end

    def list_public_for_attachable(institution_id:, attachable_type:, attachable_id:)
      scope = scope_for_attachable(
        DocumentRecord.publicly_visible.where(institution_id: institution_id),
        attachable_type: attachable_type,
        attachable_id: attachable_id
      )
      return [] if scope.nil?

      scope.order(:issued_on, :id).map { |record| RecordMapper.record_to_document(record) }
    end

    def list_public_for_ledger_entries(institution_id:, ledger_entry_ids:)
      DocumentRecord
        .publicly_visible
        .where(institution_id: institution_id, ledger_entry_id: ledger_entry_ids)
        .order(:issued_on, :id)
        .map { |record| RecordMapper.record_to_document(record) }
    end

    def save(document)
      record = if document.id.nil?
        DocumentRecord.new
      else
        DocumentRecord.find_by!(id: document.id, institution_id: document.institution_id)
      end
      RecordMapper.document_to_record(document, record)
      record.save!
      RecordMapper.record_to_document(record)
    end

    private

      def scope_for_attachable(scope, attachable_type:, attachable_id:)
        case attachable_type.to_s
        when DocumentTarget::LEDGER_ENTRY then scope.where(ledger_entry_id: attachable_id)
        when DocumentTarget::POST then scope.where(post_id: attachable_id)
        end
      end
  end
end
