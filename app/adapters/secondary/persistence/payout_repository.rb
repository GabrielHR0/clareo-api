module Persistence
  # Implementa Repositories::PayoutRepository.
  class PayoutRepository
    def find(id)
      record = preload(id: id)
      record && RecordMapper.record_to_payout(record)
    end

    def list_by_institution(institution_id, status: nil)
      scope = PayoutRecord.where(institution_id: institution_id)
      scope = scope.where(status: status.to_s) if status
      scope.includes(institution_record: :user_record)
        .order(created_at: :desc)
        .map { |record| RecordMapper.record_to_payout(record) }
    end

    # Quanto uma instituição tem a receber e ainda não recebeu. Só existe no
    # caminho :pix_payout: no :subaccount o dinheiro já está na subconta dela.
    #
    # Soma em SQL para não carregar todas as doações. Espelha
    # DonationSplit#entitlement_of, porém aplicado sobre net_amount_brl, que
    # só existe para doações recebidas.
    def pending_amount_for(institution_id)
      # Subconsulta em vez de LEFT JOIN: evita duplicar a linha de cada doação
      # que tem mais de um payout elegível.
      already_paid = PayoutRecord
        .where(status: %w[pending processing completed])
        .select(:donation_id)

      total = DonationRecord
        .received
        .where(institution_id: institution_id)
        .where.not(id: already_paid)
        .joins(:donation_split_records)
        .where(donation_split_records: { recipient: "institution", status: %w[pending done] })
        .sum("ROUND(donations.net_amount_brl * donation_split_records.percentage / 100, 2)")

      Money.build(total || 0)
    end

    def save(payout)
      record = PayoutRecord.find_by(id: payout.id) || PayoutRecord.new
      institution_record = InstitutionRecord.find_by!(id: payout.institution.id)
      RecordMapper.payout_to_record(payout, record)
      record.institution_id = institution_record.id
      record.save!
      RecordMapper.record_to_payout(record)
    end

    private

    def preload(id)
      PayoutRecord.includes(institution_record: :user_record).find_by(id: id)
    end
  end
end
