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
    admin = UserRecord.find_or_initialize_by(email: DEV_ADMIN_EMAIL)

    if admin.new_record?
      admin.assign_attributes(
        name: "Admin Clareo",
        role: "platform_admin",
        password: DEV_ADMIN_PASSWORD
      )
      admin.save!
      puts "criando dados de desenvolvimento"
    else
      puts "dados de desenvolvimento ja existem"
    end

    institution = InstitutionRecord.find_or_initialize_by(cnpj: "66625514000140")
    institution.assign_attributes(
      user_record: admin,
      legal_name: "Instituto Semear",
      trade_name: "Semear",
      settlement_strategy: "subaccount",
      legal_entity_kind: "ltda",
      declared_monthly_revenue: 50_000,
      contact_email: "financeiro@institutosemear.org",
      mobile_phone: "11988887777",
      address_street: "Rua Fernando Orlandi",
      address_number: "544",
      address_neighborhood: "Jardim Pedra Branca",
      address_postal_code: "14079-452",
      address_city: "Ribeirão Preto",
      description: "Transparência do começo ao fim para famílias do Vale do Jequitinhonha.",
      slug: "instituto-semear",
      status: "active",
      registration_status: "approved"
    )
    institution.save!

    # A estratégia pix_payout não exige CNPJ, que é o caminho de pessoa física.
    creator = InstitutionRecord.find_or_initialize_by(legal_name: "Criador de Conteúdo")
    creator.assign_attributes(
      user_record: admin,
      settlement_strategy: "pix_payout",
      pix_key: "financeiro@criador.com",
      status: "active"
    )
    creator.save!

    # A assinatura é por instituição: cada tenant paga o seu plano. As duas
    # abaixo pertencem ao mesmo admin, e é exatamente esse o caso que o modelo
    # anterior não permitia.
    pro_subscription = SubscriptionRecord.find_or_initialize_by(institution_record: institution)
    pro_subscription.plan_record = PlanRecord.find_by!(code: "pro")
    pro_subscription.save!

    free_subscription = SubscriptionRecord.find_or_initialize_by(institution_record: creator)
    free_subscription.plan_record = PlanRecord.find_by!(code: "free")
    free_subscription.save!

    donation = DonationRecord.find_or_initialize_by(reference: "don_seed_0001")
    donation.assign_attributes(
      institution_record: institution,
      donor_name: "João Silva",
      donor_email: "joao@example.com",
      amount_brl: 100.00,
      payment_method: "pix",
      status: "pending"
    )
    donation.save!

    campaign = CampaignRecord.find_or_initialize_by(
      institution_id: institution.id,
      title: "Cestas Básicas para 200 Famílias no Vale do Jequitinhonha"
    )
    campaign.assign_attributes(
      description: "Entregas semanais de alimentos e itens de higiene para famílias em situação de vulnerabilidade.",
      goal_brl: 24_000,
      starts_on: Date.current - 14.days,
      ends_on: Date.current + 21.days,
      status: "active"
    )
    campaign.save!

    post = PostRecord.find_or_initialize_by(
      institution_id: institution.id,
      campaign_id: campaign.id,
      title: "Mapeamento das 200 famílias concluído"
    )
    post.assign_attributes(
      content: "O cadastro socioeconômico foi concluído junto às lideranças comunitárias locais.",
      post_type: "update",
      status: "published",
      published_at: Time.current - 2.days
    )
    post.save!

    puts "admin: #{DEV_ADMIN_EMAIL} / #{DEV_ADMIN_PASSWORD}"
    puts "instituicao publica: #{institution.legal_name} (/institutions/#{institution.slug})"
    puts "campanha: #{campaign.title}"
  end
end

Seeds.run
