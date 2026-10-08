# Seeds idempotentes. Executar com: bin/rails db:seed
#
# Os planos não são configuração livre: `features` é texto de apresentação, lido
# no marketing e nunca consultado pelo domínio para autorizar nada. O que
# autoriza é o status da assinatura da própria instituição.

module Seeds
  PLANS = [
    {
      code: "free",
      name: "Básico",
      price_brl: 0,
      features: [ "Perfil público", "Feed de transparência", "Comprovantes" ]
    },
    {
      code: "pro",
      name: "Pro",
      price_brl: 97.00,
      features: [
        "Campanhas com meta",
        "Prestação de contas com parecer",
        "Exportação DOAR",
        "Suporte por email"
      ]
    },
    {
      code: "enterprise",
      name: "Enterprise",
      price_brl: 497.00,
      features: [
        "Tudo do Pro",
        "Gerente de conta",
        "SLA de suporte"
      ]
    }
  ].freeze

  DEV_ADMIN_EMAIL = "admin@clareo.com.br"
  DEV_ADMIN_PASSWORD = "senha-de-desenvolvimento-123"

  module_function

  def run
    seed_plans
    seed_development_data_if_needed
  end

  def seed_plans
    PLANS.each do |attributes|
      plan = PlanRecord.find_or_initialize_by(code: attributes[:code])

      plan.assign_attributes(attributes)
      plan.save!

      puts "plano #{plan.code} ok"
    end
  end

  def seed_development_data_if_needed
    return if Rails.env.production?

    # Chaveado no email, não em UserRecord.exists?: um run anterior que falhou
    # no meio deixa registro parcial e não deve impedir o seed de terminar.
    admin = UserRecord.find_by(email: DEV_ADMIN_EMAIL)

    if admin.nil?
      admin = UserRecord.create!(
        email: DEV_ADMIN_EMAIL,
        name: "Admin Clareo",
        role: "platform_admin",
        password: DEV_ADMIN_PASSWORD
      )
      puts "criando dados de desenvolvimento"
    else
      puts "dados de desenvolvimento ja existem"
      return
    end

    institution = InstitutionRecord.create!(
      user_record: admin,
      legal_name: "Instituto Semear",
      trade_name: "Semear",
      settlement_strategy: "subaccount",
      cnpj: "66625514000140",
      legal_entity_kind: "ltda",
      declared_monthly_revenue: 50_000,
      contact_email: "financeiro@institutosemear.org",
      mobile_phone: "11988887777",
      address_street: "Rua Fernando Orlandi",
      address_number: "544",
      address_neighborhood: "Jardim Pedra Branca",
      address_postal_code: "14079-452",
      address_city: "Ribeirão Preto",
      status: "active",
      registration_status: "pending"
    )

    # A estratégia pix_payout não exige CNPJ, que é o caminho de pessoa física.
    creator = InstitutionRecord.create!(
      user_record: admin,
      legal_name: "Criador de Conteúdo",
      settlement_strategy: "pix_payout",
      pix_key: "financeiro@criador.com",
      status: "active"
    )

    # A assinatura é por instituição: cada tenant paga o seu plano. As duas
    # abaixo pertencem ao mesmo admin, e é exatamente esse o caso que o modelo
    # anterior não permitia.
    SubscriptionRecord.create!(
      institution_record: institution,
      plan_record: PlanRecord.find_by!(code: "pro")
    )

    SubscriptionRecord.create!(
      institution_record: creator,
      plan_record: PlanRecord.find_by!(code: "free")
    )

    DonationRecord.create!(
      institution_record: institution,
      donor_name: "João Silva",
      donor_email: "joao@example.com",
      amount_brl: 100.00,
      payment_method: "pix",
      reference: "don_seed_0001",
      status: "pending"
    )

    puts "admin: #{DEV_ADMIN_EMAIL} / #{DEV_ADMIN_PASSWORD}"
    puts "instituicao: #{institution.legal_name}"
  end
end

Seeds.run
