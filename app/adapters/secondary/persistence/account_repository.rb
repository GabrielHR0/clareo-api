module Persistence
  # Implementa Repositories::AccountRepository.
  class AccountRepository
    def find(institution_id:, code:)
      record = AccountRecord.find_by(institution_id: institution_id, code: code.to_s)
      record && RecordMapper.record_to_account(record)
    end

    def find_by_id(institution_id:, id:)
      record = AccountRecord.find_by(institution_id: institution_id, id: id)
      record && RecordMapper.record_to_account(record)
    end

    def find_by_ids(institution_id:, ids:)
      AccountRecord
        .where(institution_id: institution_id, id: ids)
        .order(:code)
        .map { |record| RecordMapper.record_to_account(record) }
    end

    def list_by_institution(institution_id)
      AccountRecord.where(institution_id: institution_id).order(:code).map do |record|
        RecordMapper.record_to_account(record)
      end
    end

    def list_active(institution_id)
      AccountRecord.active.where(institution_id: institution_id).order(:code).map do |record|
        RecordMapper.record_to_account(record)
      end
    end

    def list_by_nature(institution_id, nature)
      AccountRecord.where(institution_id: institution_id, nature: nature.to_s).order(:code).map do |record|
        RecordMapper.record_to_account(record)
      end
    end

    def save(account)
      record = AccountRecord.find_or_initialize_by(
        institution_id: account.institution_id,
        code: account.code
      )
      RecordMapper.account_to_record(account, record)
      record.save!
      RecordMapper.record_to_account(record)
    end

    # Idempotente por (institution_id, code): o que já existe é deixado como
    # está. A instituição pode ter renomeado a conta ou desativado uma, e
    # reseedar não pode desfazer isso.
    def seed_template!(institution_id)
      created = 0

      AccountTemplate.build_for(institution_id: institution_id).each do |account|
        next if AccountRecord.exists?(institution_id: institution_id, code: account.code)

        RecordMapper.account_to_record(account).save!
        created += 1
      end

      created
    end
  end
end
