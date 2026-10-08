module Persistence
  # Implementa Repositories::InstitutionRepository.
  class InstitutionRepository
    def find(id)
      record = InstitutionRecord.find_by(id: id)
      record && RecordMapper.record_to_institution(record)
    end

    def find_by_cnpj(cnpj)
      record = InstitutionRecord.find_by(cnpj: cnpj.to_s)
      record && RecordMapper.record_to_institution(record)
    end

    def list_by_user(user_id)
      InstitutionRecord.where(user_id: user_id).order(:id).map do |record|
        RecordMapper.record_to_institution(record)
      end
    end

    def count_by_user(user_id)
      InstitutionRecord.where(user_id: user_id).count
    end

    def save(institution, user_id: nil)
      record = record_for(institution)
      RecordMapper.institution_to_record(institution, record, user_id: user_id)

      raise InvalidInstitution, "user is required to persist an institution" if record.user_id.nil?

      record.save!
      RecordMapper.record_to_institution(record)
    end

    # Criação com a subconta do provedor em jogo: institution e o vínculo do
    # provedor precisam ser gravados juntos, ou o registro fica meio ligado.
    def save_with_provider!(institution:, user_id:, account_id:, wallet_id:)
      record = record_for(institution)
      RecordMapper.institution_to_record(institution, record, user_id: user_id)
      record.asaas_account_id = account_id
      record.asaas_wallet_id = wallet_id
      record.save!
      RecordMapper.record_to_institution(record)
    end

    private

    # id nil significa agregado novo: quem atribui o id é o banco.
    def record_for(institution)
      return InstitutionRecord.new if institution.id.nil?

      InstitutionRecord.find_by(id: institution.id) || InstitutionRecord.new
    end
  end
end
