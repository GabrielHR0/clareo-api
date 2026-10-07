module Persistence
  # Implementa Repositories::DonationRepository.
  class DonationRepository
    def find(id)
      record = preload(id: id)
      record && RecordMapper.record_to_donation(record)
    end

    def find_by_reference(reference)
      record = preload(reference: reference.to_s)
      record && RecordMapper.record_to_donation(record)
    end

    # Chave de reconciliação com o webhook: o provedor manda o id do pagamento
    # dele, não o nosso.
    def find_by_provider_payment_id(provider_payment_id)
      record = preload(asaas_payment_id: provider_payment_id.to_s)
      record && RecordMapper.record_to_donation(record)
    end

    def list_by_institution(institution_id, status: nil)
      scope = DonationRecord.where(institution_id: institution_id)
      scope = scope.where(status: status.to_s) if status
      scope.includes(:donation_split_records, institution_record: :user_record)
        .order(created_at: :desc)
        .map { |record| RecordMapper.record_to_donation(record) }
    end

    # Doação e splits numa transação: split gravado sem a doação, ou donationsem
    # os splits, é estado que a reconciliação não sabe explicar.
    def save(donation)
      saved_record = DonationRecord.transaction do
        record = record_for(donation)
        institution_record = InstitutionRecord.find_by!(id: donation.institution.id)

        RecordMapper.donation_to_record(donation, record, institution_record)
        record.save!

        persist_splits(donation, record, institution_record)
        record
      end

      # Relê do banco para devolver o agregado completo: a entidade recebida
      # continua com id nil, porque quem atribui id é o banco, não o adapter.
      RecordMapper.record_to_donation(preload(id: saved_record.id))
    end

    private

    # id nil significa agregado novo: quem atribui o id é o banco.
    def record_for(donation)
      return DonationRecord.new if donation.id.nil?

      DonationRecord.find_by(id: donation.id) || DonationRecord.new
    end

    def preload(conditions)
      DonationRecord.includes(:donation_split_records, institution_record: :user_record)
        .find_by(conditions)
    end

    def persist_splits(donation, donation_record, institution_record)
      donation_record.donation_split_records.destroy_all

      donation.splits.each do |split|
        RecordMapper.split_to_record(
          split,
          donation_record: donation_record,
          institution_record: split.recipient == :institution ? institution_record : nil
        ).save!
      end
    end
  end
end
