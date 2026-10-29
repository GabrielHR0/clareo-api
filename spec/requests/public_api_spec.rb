require_relative "../domain_helper"
require "rails_helper"

RSpec.describe "API pública", type: :request do
  let(:institution_repository) { Persistence::InstitutionRepository.new }
  let(:account_repository) { Persistence::AccountRepository.new }
  let(:campaign_repository) { Persistence::CampaignRepository.new }
  let(:ledger_entry_repository) { Persistence::LedgerEntryRepository.new }
  let(:post_repository) { Persistence::PostRepository.new }
  let(:document_repository) { Persistence::DocumentRepository.new }
  let(:report_repository) { Persistence::AccountabilityReportRepository.new }

  let(:user) do
    UserRecord.create!(
      email: "public-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Revisor",
      role: "platform_admin",
      password: "senha-de-teste-123"
    )
  end

  let(:institution) do
    institution_repository.save(
      Institution.new(
        user_id: user.id,
        legal_name: "Instituto Semear",
        trade_name: "Semear",
        settlement_strategy: :pix_payout,
        pix_key: "financeiro@semear.org",
        status: :active,
        slug: "instituto-semear",
        description: "Transparência do começo ao fim."
      )
    )
  end

  let(:period_start) { Date.new(2026, 1, 1) }
  let(:period_end) { Date.new(2026, 1, 31) }

  let(:income_account) do
    account_repository.save(
      Account.build(institution_id: institution.id, code: "4.1", name: "Doações", nature: :income)
    )
  end

  let(:expense_account) do
    account_repository.save(
      Account.build(institution_id: institution.id, code: "5.1", name: "Material", nature: :expense)
    )
  end

  let(:campaign) do
    campaign_repository.save(
      Campaign.build(
        institution_id: institution.id,
        title: "Campanha do inverno",
        description: "Agasalhos para famílias",
        goal: "10000",
        starts_on: period_start,
        ends_on: period_end
      )
    )
  end

  def json
    JSON.parse(response.body)
  end

  def posted_entry(kind:, amount:, account:, campaign_id: nil)
    ledger_entry_repository.save(
      LedgerEntry.build(
        institution_id: institution.id,
        account_id: account.id,
        campaign_id: campaign_id,
        kind: kind,
        amount: amount,
        description: "Lançamento",
        status: :posted,
        posted_on: Date.new(2026, 1, 10)
      )
    )
  end

  def publish_report(income:, expense: nil)
    entries = [ AccountabilityReportEntry.from_ledger_entry(entry: income, account: income_account) ]
    if expense
      entries << AccountabilityReportEntry.from_ledger_entry(entry: expense, account: expense_account)
    end

    report = AccountabilityReport.build(
      institution_id: institution.id,
      campaign_id: income.campaign_id,
      title: "Prestação de contas de janeiro",
      summary: "Recursos recebidos e aplicados.",
      period_start: period_start,
      period_end: period_end
    )
    report.submit!(entries: entries, at: Time.utc(2026, 2, 1, 10))
    report = report_repository.save(report, sync_entries: true)
    report.start_review!(reviewer_id: user.id, at: Time.utc(2026, 2, 2, 9))
    report = report_repository.save(report)
    report.approve!(reviewer_id: user.id, opinion: "Conferido", at: Time.utc(2026, 2, 3, 9))
    report = report_repository.save(report)
    report.publish!(at: Time.utc(2026, 2, 4, 9))
    report_repository.save(report)
  end

  describe "GET /api/v1/public/institutions/:slug" do
    it "devolve perfil, resumo e campanhas visíveis" do
      active = campaign
      closed = campaign_repository.save(
        Campaign.build(
          institution_id: institution.id,
          title: "Campanha encerrada",
          description: "Histórico",
          goal: "5000",
          starts_on: period_start,
          ends_on: period_end,
          status: :closed
        )
      )
      paused = campaign_repository.save(
        Campaign.build(
          institution_id: institution.id,
          title: "Campanha pausada",
          description: "Não deve aparecer",
          goal: "5000",
          starts_on: period_start,
          ends_on: period_end
        )
      )
      paused.pause!
      campaign_repository.save(paused)

      get "/api/v1/public/institutions/instituto-semear"

      expect(response).to have_http_status(:ok)
      expect(json.dig("institution", "slug")).to eq("instituto-semear")
      expect(json.dig("summary", "balance_brl")).to eq("0.00")
      expect(json["campaigns"].map { |item| item["id"] }).to contain_exactly(active.id, closed.id)
    end

    it "não expõe instituição sem slug, inativa ou inexistente" do
      draft = institution_repository.save(
        Institution.new(
          user_id: user.id,
          legal_name: "Rascunho",
          settlement_strategy: :pix_payout,
          pix_key: "r@x.org",
          status: :draft,
          slug: "instituto-rascunho"
        )
      )

      get "/api/v1/public/institutions/instituto-rascunho"
      expect(response).to have_http_status(:not_found)
      expect(draft).not_to be_public_profile_ready

      get "/api/v1/public/institutions/nao-existe"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/public/institutions/:slug/feed" do
    it "lista só posts publicados e filtra por campanha" do
      visible = post_repository.save(
        Post.build(
          institution_id: institution.id,
          campaign_id: campaign.id,
          title: "Dentro da campanha",
          content: "Conteúdo",
          published_at: Time.utc(2026, 1, 10)
        )
      )
      post_repository.save(
        Post.build(
          institution_id: institution.id,
          title: "Fora da campanha",
          content: "Conteúdo",
          published_at: Time.utc(2026, 1, 11)
        )
      )
      hidden = Post.build(
        institution_id: institution.id,
        title: "Oculto",
        content: "Conteúdo",
        published_at: Time.utc(2026, 1, 12)
      )
      hidden.hide!
      post_repository.save(hidden)

      get "/api/v1/public/institutions/instituto-semear/feed",
        params: { campaign_id: campaign.id }

      expect(response).to have_http_status(:ok)
      expect(json["posts"].map { |post| post["id"] }).to eq([ visible.id ])
    end
  end

  describe "GET /api/v1/public/institutions/:slug/campaigns/:id" do
    it "devolve meta e progresso derivados do razão" do
      posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      posted_entry(kind: :expense, amount: "40", account: expense_account, campaign_id: campaign.id)

      get "/api/v1/public/institutions/instituto-semear/campaigns/#{campaign.id}"

      expect(response).to have_http_status(:ok)
      expect(json.dig("campaign", "goal_brl")).to eq("10000.00")
      expect(json.dig("summary", "declared_income_brl")).to eq("100.00")
      expect(json.dig("summary", "expense_brl")).to eq("40.00")
      expect(json.dig("summary", "balance_brl")).to eq("60.00")
    end
  end

  describe "GET /api/v1/public/accountability_reports/:id" do
    it "expõe o snapshot publicado e só documentos públicos" do
      income = posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      report = publish_report(income: income)

      public_document = document_repository.save(
        Document.build(
          institution_id: institution.id,
          target: DocumentTarget.for_ledger_entry(income.id),
          kind: :nota_fiscal,
          public: true
        )
      )
      document_repository.save(
        Document.build(
          institution_id: institution.id,
          target: DocumentTarget.for_ledger_entry(income.id),
          kind: :recibo
        )
      )

      get "/api/v1/public/accountability_reports/#{report.id}"

      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "total_income_brl")).to eq("100.00")
      expect(json.dig("accountability_report", "entries").size).to eq(1)
      documents = json.dig("accountability_report", "entries", 0, "documents")
      expect(documents.map { |document| document["id"] }).to eq([ public_document.id ])
    end

    it "não expõe rascunho, relatório não publicado ou instituição inativa" do
      income = posted_entry(kind: :income, amount: "100", account: income_account)
      draft = AccountabilityReport.build(
        institution_id: institution.id,
        title: "Rascunho",
        summary: "Em elaboração",
        period_start: period_start,
        period_end: period_end
      )
      draft = report_repository.save(draft)

      get "/api/v1/public/accountability_reports/#{draft.id}"
      expect(response).to have_http_status(:not_found)

      report = publish_report(income: income)
      institution.block!
      institution_repository.save(institution)

      get "/api/v1/public/accountability_reports/#{report.id}"
      expect(response).to have_http_status(:not_found)
    end
  end
end
