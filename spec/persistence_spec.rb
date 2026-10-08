require_relative "domain_helper"
require "rails_helper"

RSpec.describe "persistência" do
  let(:institution_repository) { Persistence::InstitutionRepository.new }
  let(:donation_repository) { Persistence::DonationRepository.new }
  let(:payout_repository) { Persistence::PayoutRepository.new }
  let(:plan_repository) { Persistence::PlanRepository.new }
  let(:subscription_repository) { Persistence::SubscriptionRepository.new }
  let(:webhook_repository) { Persistence::WebhookEventRepository.new }

  let(:user) do
    UserRecord.create!(
      email: "owner-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Administrador",
      role: "institution_admin",
      password: "senha-de-teste-123"
    )
  end

  # id nil: agregado novo. Quem atribui o id é o banco.
  # O dono vem no agregado: sem ele o domínio não tem caminho até a assinatura.
  def nova_instituicao(**overrides)
    Institution.new(
      user_id: user.id,
      legal_name: "Instituto Persistido",
      settlement_strategy: :pix_payout,
      pix_key: "financeiro@instituto.org",
      status: :active,
      **overrides
    )
  end

  def instituicao_pj(cnpj)
    Institution.new(
      user_id: user.id,
      legal_name: "Instituto Com CNPJ",
      settlement_strategy: :subaccount,
      cnpj: cnpj,
      legal_entity_kind: :ltda,
      declared_monthly_revenue: "50000",
      contact_email: "financeiro@instituto.org",
      mobile_phone: "11988887777",
      address: Address.build(
        street: "Rua A", number: "1", neighborhood: "B", postal_code: "14079-452"
      ),
      status: :active
    )
  end

  describe "InstitutionRepository" do
    it "grava e lê um agregado do tipo pix_payout" do
      saved = institution_repository.save(nova_instituicao)

      expect(saved.id).to be_present
      expect(saved).to be_pix_payout
      expect(institution_repository.find(saved.id).legal_name).to eq("Instituto Persistido")
    end

    it "atribui o id vindo do banco, não do agregado" do
      saved = institution_repository.save(nova_instituicao)

      expect(saved.id).to be_a(Integer)
    end

    it "exige o dono, porque sem ele a instituição não alcança a assinatura" do
      expect { Institution.new(legal_name: "Sem Dono", settlement_strategy: :pix_payout, pix_key: "k@x.org") }
        .to raise_error(InvalidInstitution, /owner is required/)
    end

    it "filtra por cnpj, que é único no sistema inteiro" do
      saved = institution_repository.save(instituicao_pj("66625514000140"))

      expect(institution_repository.find_by_cnpj("66625514000140").id).to eq(saved.id)
    end

    it "impede duas instituições com o mesmo cnpj" do
      institution_repository.save(instituicao_pj("66625514000140"))

      # A validação do model pega antes do índice único do banco, o que dá
      # mensagem de erro utilizável. O índice continua sendo a rede de proteção
      # contra corrida entre duas requisições.
      expect { institution_repository.save(instituicao_pj("66625514000140")) }
        .to raise_error(ActiveRecord::RecordInvalid, /Cnpj/)
    end

    it "lista e conta por usuário" do
      2.times do |i|
        institution_repository.save(nova_instituicao(legal_name: "Inst #{i}", pix_key: "k#{i}@x.org"))
      end

      expect(institution_repository.list_by_user(user.id).size).to eq(2)
      expect(institution_repository.count_by_user(user.id)).to eq(2)
    end

    it "grava o vínculo com o provedor em uma única transação" do
      saved = institution_repository.save_with_provider!(
        institution: nova_instituicao,
        account_id: "acc_123",
        wallet_id: "wal_456"
      )

      reloaded = institution_repository.find(saved.id)
      expect(reloaded.asaas_account_id).to eq("acc_123")
      expect(reloaded.asaas_wallet_id).to eq("wal_456")
    end

    it "devolve nil para o que não existe, em vez de explodir" do
      expect(institution_repository.find(999_999)).to be_nil
      expect(institution_repository.find_by_cnpj("00000000000000")).to be_nil
    end
  end

  describe "DonationRepository" do
    let(:institution) do
          institution_repository.save(nova_instituicao)
        end

    def nova_doacao(**overrides)
      Donation.new(
        institution: institution,
        donor_name: "Doador",
        amount: "100.00",
        payment_method: :pix,
        reference: "don_#{SecureRandom.hex(4)}",
        splits: [
          DonationSplit.for_institution(institution: institution, percentage: 94),
          DonationSplit.for_platform(percentage: 6)
        ],
        **overrides
      )
    end

    it "grava a doação e os dois splits, que somam 100%" do
      saved = donation_repository.save(nova_doacao)

      expect(saved.id).to be_present
      expect(saved.status).to eq(:pending)
      expect(saved.splits.size).to eq(2)
      expect(Percentage.sum(saved.splits.map(&:percentage))).to be_full
    end

    it "encontra por reference, que é a chave de idempotência" do
      saved = donation_repository.save(nova_doacao)

      expect(donation_repository.find_by_reference(saved.reference.to_s).id).to eq(saved.id)
    end

    it "encontra por provider_payment_id, que é o que o webhook manda" do
      donation = nova_doacao
      donation.confirm_receipt!(asaas_payment_id: "pay_abc", net_amount: "98.01", at: Time.current)
      saved = donation_repository.save(donation)

      reloaded = donation_repository.find_by_provider_payment_id("pay_abc")
      expect(reloaded.id).to eq(saved.id)
      expect(reloaded).to be_received
      expect(reloaded.net_amount).to eq(Money.brl("98.01"))
    end

    it "recusa reference duplicada, que criaria dois registros para uma doação" do
      # Cenário real: um retry da criação da cobrança reusa a reference. O
      # mesmo agregado re-salvo atualiza; uma doação nova com a mesma
      # reference é que precisa falhar.
      existing = donation_repository.save(nova_doacao)
      reloaded = donation_repository.find(existing.id)
      reloaded.confirm_receipt!(asaas_payment_id: "pay_upd", net_amount: "98.01", at: Time.current)

      updated = donation_repository.save(reloaded)
      expect(updated.status).to eq(:received)

      duplicada = nova_doacao(reference: existing.reference.to_s)
      expect { donation_repository.save(duplicada) }
        .to raise_error(ActiveRecord::RecordInvalid, /Reference/)
    end

    it "preserva o net_amount, que só existe após o recebimento" do
      donation = nova_doacao
      donation.confirm_receipt!(asaas_payment_id: "pay_net", net_amount: "97.50", at: Time.current)
      saved = donation_repository.save(donation)

      expect(donation_repository.find(saved.id).net_amount).to eq(Money.brl("97.50"))
    end

    it "devolve nil para o que não existe" do
      expect(donation_repository.find(999_999)).to be_nil
      expect(donation_repository.find_by_reference("inexistente")).to be_nil
      expect(donation_repository.find_by_provider_payment_id("pay_x")).to be_nil
    end

    it "filtra por instituição e status" do
      donation_repository.save(nova_doacao)
      confirmada = nova_doacao
      confirmada.confirm_receipt!(asaas_payment_id: "pay_l", net_amount: "98.01", at: Time.current)
      donation_repository.save(confirmada)

      expect(donation_repository.list_by_institution(institution.id).size).to eq(2)
      expect(donation_repository.list_by_institution(institution.id, status: :received).size).to eq(1)
    end
  end

  describe "PayoutRepository" do
    it "soma zero quando a instituição não tem nada a receber" do
      institution = institution_repository.save(nova_instituicao)

      expect(payout_repository.pending_amount_for(institution.id)).to eq(Money.zero)
    end

    it "soma a entitlement das doações recebidas e ainda não pagas" do
      institution = institution_repository.save(nova_instituicao)
      donation = Donation.new(
        institution: institution,
        donor_name: "Doador",
        amount: "100.00",
        payment_method: :pix,
        reference: "don_pay_1",
        splits: [
          DonationSplit.for_institution(institution: institution, percentage: 94),
          DonationSplit.for_platform(percentage: 6)
        ]
      )
      donation.confirm_receipt!(asaas_payment_id: "pay_p1", net_amount: "98.01", at: Time.current)
      saved = donation_repository.save(donation)

      # 94% de 98.01 = 92.13
      expect(payout_repository.pending_amount_for(institution.id)).to eq(Money.brl("92.13"))

      payout_repository.save(
        Payout.new(
          institution: institution,
          donation: donation_repository.find(saved.id),
          amount: "92.13",
          pix_key: "financeiro@instituto.org"
        )
      )

      # Com payout concluído, não há mais o que receber.
      expect(payout_repository.pending_amount_for(institution.id)).to eq(Money.zero)
    end
  end

  describe "WebhookEventRepository" do
    let(:event_id) { "evt_#{SecureRandom.hex(6)}" }

    def record_event(id = event_id)
      webhook_repository.record(
        provider_event_id: id,
        event: "PAYMENT_RECEIVED",
        payload: { "id" => "pay_1" },
        resource_id: "pay_1",
        resource_type: "payment"
      )
    end

    it "grava o evento uma vez" do
      expect(record_event).to be(true)
      expect(webhook_repository.find_by_provider_event_id(event_id)).to be_present
    end

    it "recusa o mesmo provider_event_id, porque a entrega é at least once" do
      expect(record_event).to be(true)
      expect(record_event).to be(false)
      expect(WebhookEventRecord.where(provider_event_id: event_id).count).to eq(1)
    end

    it "conta tentativas e guarda a falha para reprocessamento" do
      record_event
      webhook_repository.mark_processing(event_id)
      webhook_repository.mark_failed(event_id, "timeout ao consultar o provedor")

      reloaded = webhook_repository.find_by_provider_event_id(event_id)
      expect(reloaded.attempts).to eq(1)
      expect(reloaded.error_message).to eq("timeout ao consultar o provedor")
    end

    it "marca como processado e limpa a contagem de erro" do
      record_event
      webhook_repository.mark_processing(event_id)
      webhook_repository.mark_failed(event_id, "erro temporario")
      webhook_repository.mark_processing(event_id)
      webhook_repository.mark_processed(event_id)

      reloaded = webhook_repository.find_by_provider_event_id(event_id)
      expect(reloaded).to be_already_processed
      expect(reloaded.attempts).to eq(2)
      expect(reloaded.error_message).to be_nil
    end
  end

  describe "PlanRepository e SubscriptionRepository" do
      let(:pro) { Plan.build(code: :pro, name: "Pro", price: "97.00") }

      # A assinatura é da instituição, então cada caso precisa da sua própria
      # instituição: duas assinaturas do mesmo usuário são a coisa esperada.
      let(:primeira) { institution_repository.save(nova_instituicao(legal_name: "Inst A", pix_key: "a@x.org")) }
      let(:segunda) { institution_repository.save(nova_instituicao(legal_name: "Inst B", pix_key: "b@x.org")) }

      before { plan_repository.save(pro) }

      it "lê planos do catálogo" do
        expect(plan_repository.find_by_code(:pro).price).to eq(Money.brl("97.00"))
        expect(plan_repository.list.map(&:code)).to include(:pro)
      end

      it "encontra a assinatura ativa da instituição" do
        institution = primeira
        subscription_repository.save(Subscription.new(institution_id: institution.id, plan: pro))

        found = subscription_repository.find_active_by_institution(institution.id)
        expect(found.plan.code).to eq(:pro)
        expect(found.institution_id).to eq(institution.id)
      end

      it "permite que um mesmo usuário tenha duas instituições em planos separados" do
        a = primeira
        b = segunda
        subscription_repository.save(Subscription.new(institution_id: a.id, plan: pro))
        subscription_repository.save(Subscription.new(institution_id: b.id, plan: pro))

        expect(subscription_repository.find_active_by_institution(a.id).id)
          .not_to eq(subscription_repository.find_active_by_institution(b.id).id)
        expect(a.user_id).to eq(b.user_id)
      end

      it "impede duas assinaturas ativas para a mesma instituição, no banco" do
        institution = primeira
        subscription_repository.save(Subscription.new(institution_id: institution.id, plan: pro))

        second = SubscriptionRecord.new(
          institution_id: institution.id,
          plan_id: PlanRecord.find_by!(code: "pro").id,
          status: "active"
        )

        expect { second.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it "permite reassinar depois de cancelar" do
        institution = primeira
        subscription_repository.save(Subscription.new(institution_id: institution.id, plan: pro))
        existing = subscription_repository.find_active_by_institution(institution.id)
        existing.cancel!
        subscription_repository.save(existing)

        expect(subscription_repository.find_active_by_institution(institution.id)).to be_nil
        expect(
          subscription_repository.save(Subscription.new(institution_id: institution.id, plan: pro))
        ).to be_present
      end
    end
end
