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

  def upsert_public_institution(admin:, cnpj:, legal_name:, trade_name:, slug:,
                                city:, postal_code:, description:, contact_email:,
                                mobile_phone:)
    institution = InstitutionRecord.find_or_initialize_by(cnpj: cnpj)
    institution.assign_attributes(
      user_record: admin,
      legal_name: legal_name,
      trade_name: trade_name,
      settlement_strategy: "subaccount",
      legal_entity_kind: "association",
      declared_monthly_revenue: 35_000,
      contact_email: contact_email,
      mobile_phone: mobile_phone,
      address_street: "Rua das Ações Sociais",
      address_number: "120",
      address_neighborhood: "Centro",
      address_postal_code: postal_code,
      address_city: city,
      description: description,
      slug: slug,
      status: "active",
      registration_status: "approved"
    )
    institution.save!

    subscription = SubscriptionRecord.find_or_initialize_by(
      institution_record: institution
    )
    subscription.plan_record = PlanRecord.find_by!(code: "pro")
    subscription.save!

    institution
  end

  def upsert_public_campaign(institution:, title:, description:, goal_brl:,
                             starts_on:, ends_on:)
    campaign = CampaignRecord.find_or_initialize_by(
      institution_id: institution.id,
      title: title
    )
    campaign.assign_attributes(
      description: description,
      goal_brl: goal_brl,
      starts_on: starts_on,
      ends_on: ends_on,
      status: "active"
    )
    campaign.save!

    campaign
  end

  def upsert_public_post(institution:, campaign:, title:, content:, published_at:)
    post = PostRecord.find_or_initialize_by(
      institution_id: institution.id,
      campaign_id: campaign.id,
      title: title
    )
    post.assign_attributes(
      content: content,
      post_type: "update",
      status: "published",
      published_at: published_at
    )
    post.save!

    post
  end

  def upsert_seed_income_account(institution)
    account = AccountRecord.find_or_initialize_by(
      institution_id: institution.id,
      code: "4.1"
    )
    account.assign_attributes(
      name: "Receitas de Doações",
      nature: "income",
      system: true,
      active: true
    )
    account.save!

    account
  end

  def upsert_seed_donations(institution:, campaign:, entries:)
    account = upsert_seed_income_account(institution)

    entries.each_with_index do |(donor_name, amount_brl), index|
      reference = "don_#{campaign.id}_#{index + 1}"
      donation = DonationRecord.find_or_initialize_by(reference: reference)

      if donation.new_record?
        received_at = Time.current - (entries.length - index).days
        donation.assign_attributes(
          institution_record: institution,
          campaign_record: campaign,
          donor_name: donor_name,
          donor_email: "doador#{index + 1}@example.com",
          amount_brl: amount_brl,
          net_amount_brl: amount_brl,
          payment_method: "pix",
          status: "received",
          received_at: received_at
        )
        donation.save!
      end

      split = DonationSplitRecord.find_or_initialize_by(
        donation_record: donation,
        institution_record: institution,
        recipient: "institution"
      )
      if split.new_record?
        split.assign_attributes(percentage: 100, status: "done")
        split.save!
      end

      entry = LedgerEntryRecord.find_or_initialize_by(donation_split_record: split)
      next if entry.persisted?

      entry.assign_attributes(
        institution_record: institution,
        account_record: account,
        campaign_record: campaign,
        kind: "income",
        origin: "donation",
        amount_brl: amount_brl,
        status: "posted",
        posted_on: [ campaign.starts_on + (index * 2).days, Date.current ].min
      )
      entry.save!
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

    extra_campaign = upsert_public_campaign(
      institution: institution,
      title: "Campanha do Agasalho no Vale do Jequitinhonha",
      description: "Casacos, cobertores e roupas infantis para enfrentar as noites frias da região.",
      goal_brl: 12_000,
      starts_on: Date.current - 3.days,
      ends_on: Date.current + 35.days
    )
    upsert_public_post(
      institution: institution,
      campaign: extra_campaign,
      title: "Primeiros 300 agasalhos já foram separados",
      content: "Voluntários organizaram as doações por tamanho antes da primeira entrega às famílias.",
      published_at: Time.current - 9.days
    )
    upsert_seed_donations(
      institution: institution,
      campaign: campaign,
      entries: [
        [ "Mariana Alves", 3_200 ],
        [ "Rafael Lima", 1_800 ],
        [ "Fernanda Souza", 1_500 ],
        [ "Bruno Martins", 900 ],
        [ "Camila Rocha", 480 ]
      ]
    )
    upsert_seed_donations(
      institution: institution,
      campaign: extra_campaign,
      entries: [
        [ "Patrícia Gomes", 1_200 ],
        [ "Eduardo Nunes", 850 ],
        [ "Larissa Almeida", 600 ],
        [ "Gustavo Ribeiro", 400 ]
      ]
    )

    rede_acolher = upsert_public_institution(
      admin: admin,
      cnpj: "45283163000167",
      legal_name: "Rede Acolher",
      trade_name: "Rede Acolher",
      slug: "rede-acolher",
      city: "São Paulo",
      postal_code: "01310-100",
      description: "Apoio humanitário, hospedagem e cuidado integral para famílias em tratamento de saúde.",
      contact_email: "contato@redeacolher.org",
      mobile_phone: "11977776666"
    )
    health_campaign = upsert_public_campaign(
      institution: rede_acolher,
      title: "Cirurgia e Tratamento do Pequeno Theo",
      description: "O Theo precisa de uma cirurgia cardíaca e de acompanhamento especializado nos próximos meses.",
      goal_brl: 45_000,
      starts_on: Date.current - 9.days,
      ends_on: Date.current + 12.days
    )
    upsert_public_post(
      institution: rede_acolher,
      campaign: health_campaign,
      title: "Exames pré-operatórios foram aprovados",
      content: "A equipe médica confirmou que o Theo está apto para a cirurgia. A família segue hospedada perto do hospital.",
      published_at: Time.current - 6.hours
    )
    upsert_public_post(
      institution: rede_acolher,
      campaign: health_campaign,
      title: "Família recebeu apoio para hospedagem",
      content: "Com os primeiros recursos, conseguimos garantir 30 dias de hospedagem para a mãe e o Theo.",
      published_at: Time.current - 4.days
    )
    upsert_seed_donations(
      institution: rede_acolher,
      campaign: health_campaign,
      entries: [
        [ "Ana Beatriz Costa", 2_500 ],
        [ "Marcelo Pereira", 1_800 ],
        [ "Juliana Castro", 1_200 ],
        [ "Thiago Fernandes", 950 ],
        [ "Renata Moreira", 700 ],
        [ "Diego Carvalho", 500 ]
      ]
    )

    maos_unidas = upsert_public_institution(
      admin: admin,
      cnpj: "11222333000181",
      legal_name: "Projeto Mãos Unidas",
      trade_name: "Mãos Unidas",
      slug: "projeto-maos-unidas",
      city: "Belo Horizonte",
      postal_code: "30140-071",
      description: "Educação, tecnologia e oportunidades para jovens de comunidades vulneráveis.",
      contact_email: "contato@maosunidas.org",
      mobile_phone: "31966665555"
    )
    education_campaign = upsert_public_campaign(
      institution: maos_unidas,
      title: "Laboratório de Informática para 120 Jovens",
      description: "Montagem de um laboratório com 20 computadores e bolsas para cursos de programação.",
      goal_brl: 18_000,
      starts_on: Date.current - 6.days,
      ends_on: Date.current + 30.days
    )
    upsert_public_post(
      institution: maos_unidas,
      campaign: education_campaign,
      title: "Laboratório entra na fase final de montagem",
      content: "As mesas, cadeiras e a rede elétrica já estão prontas. Agora faltam os computadores e os monitores.",
      published_at: Time.current - 1.day
    )
    upsert_public_post(
      institution: maos_unidas,
      campaign: education_campaign,
      title: "Primeira turma já tem 45 jovens inscritos",
      content: "As inscrições superaram a expectativa e a lista de espera para o curso de programação já foi aberta.",
      published_at: Time.current - 5.days
    )
    upsert_seed_donations(
      institution: maos_unidas,
      campaign: education_campaign,
      entries: [
        [ "Lucas Oliveira", 1_500 ],
        [ "Bianca Santos", 1_200 ],
        [ "Rodrigo Alves", 900 ],
        [ "Natália Freitas", 700 ],
        [ "Felipe Barbosa", 600 ],
        [ "Isabela Moura", 500 ]
      ]
    )

    puts "admin: #{DEV_ADMIN_EMAIL} / #{DEV_ADMIN_PASSWORD}"
    puts "instituicoes publicas: #{InstitutionRecord.where(status: "active").where.not(slug: nil).count}"
    puts "campanhas publicas: #{CampaignRecord.where(status: "active").count}"
  end
end

Seeds.run
