# Tradução entre AR records e agregados do domínio.
#
# É o único lugar que conhece os dois formatos. Nenhum outro arquivo converte,
# porque conversão espalhada vira regra de negócio escondida.
module Persistence
  module RecordMapper
    module_function

    # ---------- Institution ----------

    # O dono da instituição passou a fazer parte do agregado. Sem isso o domínio não
    # tinha caminho de uma instituição até a assinatura, e o gate de publicação
    # ficava sem lugar nenhum.
    def institution_to_record(institution, record = nil)
      record ||= InstitutionRecord.new
      record.user_id = institution.user_id
      record.legal_name = institution.legal_name
      record.trade_name = institution.trade_name
      record.settlement_strategy = institution.settlement_strategy.to_s
      record.cnpj = institution.cnpj&.digits
      record.legal_entity_kind = institution.legal_entity_kind&.to_s
      record.declared_monthly_revenue = institution.declared_monthly_revenue&.amount
      record.contact_email = institution.contact_email
      record.mobile_phone = institution.mobile_phone
      record.pix_key = institution.pix_key&.to_s

      if institution.address
        record.address_street = institution.address.street
        record.address_number = institution.address.number
        record.address_complement = institution.address.complement
        record.address_neighborhood = institution.address.neighborhood
        record.address_postal_code = institution.address.postal_code
        record.address_city = institution.address.city
      end

      record.asaas_account_id = institution.asaas_account_id
      record.asaas_wallet_id = institution.asaas_wallet_id
      record.registration_status = institution.registration_status.to_s
      record.status = institution.status.to_s
      record
    end

    def record_to_institution(record)
      Institution.new(
        id: record.id,
        user_id: record.user_id,
        legal_name: record.legal_name,
        trade_name: record.trade_name,
        settlement_strategy: record.settlement_strategy.to_sym,
        cnpj: record.cnpj,
        legal_entity_kind: record.legal_entity_kind&.to_sym,
        declared_monthly_revenue: record.declared_monthly_revenue,
        contact_email: record.contact_email,
        mobile_phone: record.mobile_phone,
        address: record.address,
        pix_key: record.pix_key,
        asaas_account_id: record.asaas_account_id,
        asaas_wallet_id: record.asaas_wallet_id,
        registration_status: record.registration_status.to_sym,
        status: record.status.to_sym
      )
    end

    # ---------- Plan ----------

    def record_to_plan(record)
      Plan.build(
        code: record.code.to_sym,
        name: record.name,
        price: record.price_brl,
        features: record.features || []
      )
    end

    def plan_to_record(plan, record = nil)
      record ||= PlanRecord.new
      record.code = plan.code.to_s
      record.name = plan.name
      record.price_brl = plan.price.amount
      record.features = plan.features
      record
    end

    # ---------- Subscription ----------

    def record_to_subscription(record)
      Subscription.new(
id: record.id,
          institution_id: record.institution_id,
          plan: record_to_plan(record.plan_record),
        provider_subscription_id: record.asaas_subscription_id,
        status: record.status.to_sym,
        current_period_ends_at: record.current_period_ends_at,
        cancelled_at: record.cancelled_at
      )
    end

    # ---------- Donation ----------

    def donation_to_record(donation, record = nil, institution_record = nil)
      record ||= DonationRecord.new
      institution_record ||= InstitutionRecord.find(donation.institution.id)
      record.institution_id = institution_record.id
      record.donor_name = donation.donor_name
      record.donor_email = donation.donor_email
      record.amount_brl = donation.amount.amount
      record.payment_method = donation.payment_method.to_s
      record.reference = donation.reference.to_s
      record.status = donation.status.to_s
      record.asaas_payment_id = donation.asaas_payment_id
      record.net_amount_brl = donation.net_amount&.amount
      record.received_at = donation.received_at
      record.refunded_at = donation.refunded_at
      record
    end

    # Os splits vêm do record de acompanha Donation, que já tem o Institution.
    # Não há recursão: Institution não guarda referência a Donation.
    # Os splits são montados antes do agregado: Donation exige splits não vazios
    # na construção, e a regra vale tanto para gravação quanto para leitura.
    def record_to_donation(record, institution = nil)
      institution ||= record_to_institution(record.institution_record)

      Donation.new(
        id: record.id,
        institution: institution,
        donor_name: record.donor_name,
        donor_email: record.donor_email,
        amount: record.amount_brl,
        payment_method: record.payment_method.to_sym,
        reference: record.reference,
        status: record.status.to_sym,
        splits: build_splits(record, institution),
        net_amount: record.net_amount_brl,
        asaas_payment_id: record.asaas_payment_id,
        received_at: record.received_at,
        refunded_at: record.refunded_at
      )
    end

    def build_splits(record, institution)
      record.donation_split_records.map do |split_record|
        DonationSplit.new(
          recipient: split_record.recipient.to_sym,
          percentage: split_record.percentage,
          institution: split_record.recipient == "institution" ? institution : nil,
          status: split_record.status.to_sym,
          total_value: split_record.total_value_brl,
          asaas_split_id: split_record.asaas_split_id
        )
      end
    end

    # ---------- DonationSplit ----------

    def split_to_record(split, donation_record:, institution_record: nil)
      record = DonationSplitRecord.new(
        donation_id: donation_record.id,
        recipient: split.recipient.to_s,
        percentage: split.percentage.value,
        status: split.status.to_s,
        total_value_brl: split.total_value&.amount,
        asaas_split_id: split.asaas_split_id,
        cancellation_reason: split.cancellation_reason&.to_s
      )

      record.institution_id = institution_record&.id
      record
    end

    # ---------- Payout ----------

    def payout_to_record(payout, record = nil)
      record ||= PayoutRecord.new
      record.institution_id = payout.institution.id
      record.donation_id = payout.donation&.id
      record.amount_brl = payout.amount.amount
      record.pix_key = payout.pix_key.to_s
      record.provider_transfer_id = payout.provider_transfer_id
      record.status = payout.status.to_s
      record.failure_reason = payout.failure_reason
      record.completed_at = payout.completed_at
      record
    end

    def record_to_payout(record)
      Payout.new(
        id: record.id,
        institution: record_to_institution(record.institution_record),
        donation: nil,
        amount: record.amount_brl,
        pix_key: record.pix_key,
        provider_transfer_id: record.provider_transfer_id,
        status: record.status.to_sym,
        failure_reason: record.failure_reason,
        completed_at: record.completed_at
      )
    end

    # ---------- WebhookEvent ----------

    def webhook_to_record(provider_event_id:, event:, payload:, resource_type:, resource_id:)
      WebhookEventRecord.new(
        provider_event_id: provider_event_id,
        event: event,
        payload: payload,
        resource_type: resource_type,
        resource_id: resource_id
      )
    end

    def record_to_webhook_event(record)
      WebhookEvent.new(
        provider_event_id: record.provider_event_id,
        event: record.event,
        payload: record.payload,
        resource_type: record.resource_type,
        resource_id: record.resource_id,
        status: record.status.to_sym,
        attempts: record.attempts,
        processed_at: record.processed_at,
        error_message: record.error_message
      )
    end
  end
end
