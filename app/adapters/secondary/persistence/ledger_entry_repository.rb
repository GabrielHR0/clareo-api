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

    def list_in_period(institution_id, from:, to:, campaign_id: nil)
      scope = LedgerEntryRecord
        .posted
        .in_period(from, to)
        .where(institution_id: institution_id)
      scope = scope.for_campaign(campaign_id) if campaign_id

      scope.order(:posted_on, :id).map { |record| RecordMapper.record_to_ledger_entry(record) }
    end

    # Receita de doação, receita declarada e despesa saem da mesma leitura.
    # Somar em três queries abriria janela para um lançamento entrar entre elas
    # e o relatório publicar total que não fecha com nenhuma linha.
    def financial_summary(institution_id, from: nil, to: nil, campaign_id: nil)
      scope = LedgerEntryRecord.posted.where(institution_id: institution_id)
      scope = scope.where("posted_on >= ?", from) if from
      scope = scope.where("posted_on <= ?", to) if to
      scope = scope.for_campaign(campaign_id) if campaign_id

      totals = scope.pick(
        Arel.sql("COALESCE(SUM(amount_brl) FILTER (WHERE kind = 'income' AND origin = 'donation'), 0)"),
        Arel.sql("COALESCE(SUM(amount_brl) FILTER (WHERE kind = 'income' AND origin = 'declared'), 0)"),
        Arel.sql("COALESCE(SUM(amount_brl) FILTER (WHERE kind = 'expense'), 0)")
      )

      FinancialSummary.build(
        donation_income: totals[0],
        declared_income: totals[1],
        expense: totals[2]
      )
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
