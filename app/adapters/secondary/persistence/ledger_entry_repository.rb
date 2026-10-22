module Persistence
  # Implementa Repositories::LedgerEntryRepository.
  class LedgerEntryRepository
    def find(id)
      record = LedgerEntryRecord.find_by(id: id)
      record && RecordMapper.record_to_ledger_entry(record)
    end

    def list_by_institution(institution_id, status: nil)
      scope = LedgerEntryRecord.where(institution_id: institution_id)
      scope = scope.where(status: status.to_s) if status
      scope.order(posted_on: :desc, id: :desc).map { |record| RecordMapper.record_to_ledger_entry(record) }
    end

    def list_in_period(institution_id, from:, to:)
      LedgerEntryRecord
        .posted
        .in_period(from, to)
        .where(institution_id: institution_id)
        .order(:posted_on, :id)
        .map { |record| RecordMapper.record_to_ledger_entry(record) }
    end

    # O que o sistema sabe que entrou. A conferência compara isto com o que a
    # instituição declarou: divergência entre os dois é o sinal de que algo
    # está errado.
    def declared_income_total(institution_id, from:, to:)
      record = LedgerEntryRecord
        .posted
        .from_donations
        .income
        .in_period(from, to)
        .where(institution_id: institution_id)
        .sum(:amount_brl)

      Money.build(record || 0)
    end

    def save(entry)
      record = LedgerEntryRecord.find_by(id: entry.id) || LedgerEntryRecord.new
      RecordMapper.ledger_entry_to_record(entry, record)
      record.save!
      RecordMapper.record_to_ledger_entry(record)
    end

    # Idempotente por donation_split_id. A entrega do provedor é at least once,
    # então reprocessar webhook não pode duplicar receita — e o índice único
    # parcial no banco é o que garante isso contra duas requisições ao mesmo
    # tempo.
    def record_donation_income!(institution_id:, donation_split_id:, amount:,
                                account_id:, posted_on:, campaign_id: nil,
                                cost_center_id: nil, description: nil)
      existing = LedgerEntryRecord.find_by(donation_split_id: donation_split_id)
      return RecordMapper.record_to_ledger_entry(existing) if existing

      entry = LedgerEntry.from_donation_split(
        institution_id: institution_id,
        donation_split_id: donation_split_id,
        account_id: account_id,
        cost_center_id: cost_center_id,
        campaign_id: campaign_id,
        amount: amount,
        description: description,
        posted_on: posted_on
      )
      save(entry)
    end
  end
end
