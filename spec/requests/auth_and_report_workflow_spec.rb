require_relative "../domain_helper"
require "rails_helper"

RSpec.describe "Autenticação e fluxo de prestação de contas", type: :request do
  let(:institution_repository) { Persistence::InstitutionRepository.new }
  let(:account_repository) { Persistence::AccountRepository.new }
  let(:campaign_repository) { Persistence::CampaignRepository.new }
  let(:ledger_entry_repository) { Persistence::LedgerEntryRepository.new }

  let(:password) { "senha-de-teste-123" }

  let(:owner) do
    UserRecord.create!(
      email: "owner-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Dono",
      role: "institution_admin",
      password: password
    )
  end

  let(:platform_admin) do
    UserRecord.create!(
      email: "admin-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Admin",
      role: "platform_admin",
      password: password
    )
  end

  let(:stranger) do
    UserRecord.create!(
      email: "stranger-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Estranho",
      role: "institution_admin",
      password: password
    )
  end

  let(:institution) do
    institution_repository.save(
      Institution.new(
        user_id: owner.id,
        legal_name: "Instituto Prestador",
        settlement_strategy: :pix_payout,
        pix_key: "financeiro@prestador.org",
        status: :active,
        slug: "instituto-prestador",
        description: "Prestamos contas."
      )
    )
  end

  let(:account) do
    account_repository.save(
      Account.build(institution_id: institution.id, code: "4.1", name: "Doações", nature: :income)
    )
  end

  def json
    JSON.parse(response.body)
  end

  def login(user)
    post "/api/v1/auth/login", params: { email: user.email, password: password }
    expect(response).to have_http_status(:ok)
    json["token"]
  end

  def auth(token)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "auth" do
    it "faz login e recusa credencial inválida" do
      token = login(owner)

      expect(token).to be_present
      expect(json.dig("user", "role")).to eq("institution_admin")

      post "/api/v1/auth/login", params: { email: owner.email, password: "errada" }
      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/institutions/#{institution.id}/accountability_reports"
      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token)
      expect(response).to have_http_status(:ok)
    end

    it "registra doador e revoga o token no logout" do
      post "/api/v1/auth/register", params: {
        email: "novo-#{SecureRandom.hex(4)}@exemplo.com",
        name: "Novo Doador",
        password: password,
        password_confirmation: password
      }
      expect(response).to have_http_status(:created)
      expect(json.dig("user", "role")).to eq("donor")

      token = json["token"]
      post "/api/v1/auth/logout", headers: auth(token)
      expect(response).to have_http_status(:no_content)

      get "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token)
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "accountability report" do
    it "percorre rascunho, revisão, publicação e leitura pública" do
      ledger_entry = ledger_entry_repository.save(
        LedgerEntry.build(
          institution_id: institution.id,
          account_id: account.id,
          kind: :income,
          amount: "100",
          description: "Doação declarada",
          status: :posted,
          posted_on: Date.new(2026, 1, 10)
        )
      )
      owner_token = login(owner)

      post "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(owner_token),
        params: {
          title: "Prestação de janeiro",
          summary: "Recursos e aplicações do mês.",
          period_start: "2026-01-01",
          period_end: "2026-01-31"
        }

      expect(response).to have_http_status(:created)
      report_id = json.dig("accountability_report", "id")
      expect(json.dig("accountability_report", "status")).to eq("draft")
      expect(json.dig("accountability_report", "entries", 0, "ledger_entry_id")).to eq(ledger_entry.id)

      post "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}/submit",
        headers: auth(owner_token)
      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "status")).to eq("submitted")

      admin_token = login(platform_admin)
      get "/api/v1/admin/accountability_reports", headers: auth(admin_token)
      expect(response).to have_http_status(:ok)
      expect(json["accountability_reports"].map { |item| item["id"] }).to include(report_id)

      post "/api/v1/admin/accountability_reports/#{report_id}/start_review",
        headers: auth(admin_token)
      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "status")).to eq("under_review")

      post "/api/v1/admin/accountability_reports/#{report_id}/approve",
        headers: auth(admin_token),
        params: { opinion: "Documentação conferida" }
      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "status")).to eq("approved")

      post "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}/publish",
        headers: auth(owner_token)
      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "status")).to eq("published")

      get "/api/v1/public/institutions/instituto-prestador/accountability_reports"
      expect(response).to have_http_status(:ok)
      expect(json["accountability_reports"].map { |item| item["id"] }).to eq([ report_id ])
    end

    it "edita o cabeçalho do rascunho e bloqueia edição após o submit" do
      ledger_entry_repository.save(
        LedgerEntry.build(
          institution_id: institution.id,
          account_id: account.id,
          kind: :income,
          amount: "50",
          description: "Doação declarada",
          status: :posted,
          posted_on: Date.new(2026, 1, 10)
        )
      )
      token = login(owner)

      post "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token),
        params: {
          title: "Título original",
          summary: "Resumo original",
          period_start: "2026-01-01",
          period_end: "2026-01-31"
        }
      report_id = json.dig("accountability_report", "id")

      patch "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}",
        headers: auth(token),
        params: {
          title: "Título corrigido",
          summary: "Resumo corrigido",
          period_start: "2026-01-01",
          period_end: "2026-01-15"
        }

      expect(response).to have_http_status(:ok)
      expect(json.dig("accountability_report", "title")).to eq("Título corrigido")
      expect(json.dig("accountability_report", "period_end")).to eq("2026-01-15")
      expect(json.dig("accountability_report", "entries").size).to eq(1)

      post "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}/submit",
        headers: auth(token)
      expect(response).to have_http_status(:ok)

      patch "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}",
        headers: auth(token),
        params: {
          title: "Tarde demais",
          summary: "Não pode",
          period_start: "2026-01-01",
          period_end: "2026-01-31"
        }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to match(/cannot edit/)
    end

    it "recusa campanha de outra instituição sem estourar a FK" do
      other_institution = institution_repository.save(
        Institution.new(
          user_id: stranger.id,
          legal_name: "Instituto Alheio",
          settlement_strategy: :pix_payout,
          pix_key: "financeiro@alheio.org",
          status: :active,
          slug: "instituto-alheio"
        )
      )
      other_campaign = campaign_repository.save(
        Campaign.build(
          institution_id: other_institution.id,
          title: "Campanha alheia",
          description: "Outra causa",
          goal: "1000",
          starts_on: Date.new(2026, 1, 1),
          ends_on: Date.new(2026, 1, 31)
        )
      )
      token = login(owner)

      post "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token),
        params: {
          title: "Tentativa",
          summary: "Campanha cruzada",
          period_start: "2026-01-01",
          period_end: "2026-01-31",
          campaign_id: other_campaign.id
        }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to match(/campaign does not belong/)
    end

    it "recusa escrita de quem não administra a instituição" do
      token = login(stranger)

      post "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token),
        params: {
          title: "Tentativa",
          summary: "Sem permissão",
          period_start: "2026-01-01",
          period_end: "2026-01-31"
        }

      expect(response).to have_http_status(:forbidden)
    end

    it "exige platform_admin na fila de revisão" do
      token = login(owner)

      get "/api/v1/admin/accountability_reports", headers: auth(token)
      expect(response).to have_http_status(:forbidden)
    end

    it "recusa submit de rascunho sem lançamento no período" do
      token = login(owner)
      post "/api/v1/institutions/#{institution.id}/accountability_reports",
        headers: auth(token),
        params: {
          title: "Vazio",
          summary: "Sem lançamentos",
          period_start: "2026-01-01",
          period_end: "2026-01-31"
        }
      report_id = json.dig("accountability_report", "id")

      post "/api/v1/institutions/#{institution.id}/accountability_reports/#{report_id}/submit",
        headers: auth(token)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["error"]).to match(/at least one entry/)
    end
  end
end
