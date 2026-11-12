require_relative "../domain_helper"
require "rails_helper"

RSpec.describe "persistência da prestação de contas" do
  let(:institution_repository) { Persistence::InstitutionRepository.new }
  let(:account_repository) { Persistence::AccountRepository.new }
  let(:campaign_repository) { Persistence::CampaignRepository.new }
  let(:ledger_entry_repository) { Persistence::LedgerEntryRepository.new }
  let(:post_repository) { Persistence::PostRepository.new }
  let(:document_repository) { Persistence::DocumentRepository.new }
  let(:report_repository) { Persistence::AccountabilityReportRepository.new }

  let(:user) do
    UserRecord.create!(
      email: "report-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Revisor",
      role: "platform_admin",
      password: "senha-de-teste-123"
    )
  end

  let(:institution) do
    institution_repository.save(
      Institution.new(
        user_id: user.id,
        legal_name: "Instituto Transparente",
        trade_name: "Transparente",
        settlement_strategy: :pix_payout,
        pix_key: "financeiro@transparente.org",
        status: :active,
        slug: "instituto-transparente",
        description: "Prestamos contas de cada doação."
      )
    )
  end

  let(:other_institution) do
    institution_repository.save(
      Institution.new(
        user_id: user.id,
        legal_name: "Instituto Alheio",
        settlement_strategy: :pix_payout,
        pix_key: "financeiro@alheio.org",
        status: :active,
        slug: "instituto-alheio"
      )
    )
  end

  let(:period_start) { Date.new(2026, 1, 1) }
  let(:period_end) { Date.new(2026, 1, 31) }

  let(:income_account) do
    account_repository.save(
      Account.build(
        institution_id: institution.id,
        code: "4.1",
        name: "Doações",
        nature: :income
      )
    )
  end

  let(:expense_account) do
    account_repository.save(
      Account.build(
        institution_id: institution.id,
        code: "5.1",
        name: "Material",
        nature: :expense
      )
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

  def posted_entry(kind:, amount:, account:, campaign_id: nil, posted_on: Date.new(2026, 1, 10))
    ledger_entry_repository.save(
      LedgerEntry.build(
        institution_id: institution.id,
        account_id: account.id,
        campaign_id: campaign_id,
        kind: kind,
        amount: amount,
        description: "Lançamento de teste",
        status: :posted,
        posted_on: posted_on
      )
    )
  end

  def snapshot(entry, account)
    AccountabilityReportEntry.from_ledger_entry(entry: entry, account: account)
  end

  def draft_report
    AccountabilityReport.build(
      institution_id: institution.id,
      campaign_id: campaign.id,
      title: "Prestação de contas de janeiro",
      summary: "Recursos recebidos e aplicados no período.",
      period_start: period_start,
      period_end: period_end
    )
  end

  describe "AccountabilityReportRepository" do
    it "grava o cabeçalho e o snapshot na mesma transação" do
      income = posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      expense = posted_entry(kind: :expense, amount: "40", account: expense_account, campaign_id: campaign.id)

      report = draft_report
      report.submit!(
        entries: [ snapshot(income, income_account), snapshot(expense, expense_account) ],
        at: Time.utc(2026, 2, 1, 10)
      )

      saved = report_repository.save(report, sync_entries: true)
      reloaded = report_repository.find(saved.id)

      expect(reloaded).to be_submitted
      expect(reloaded.entries.size).to eq(2)
      expect(reloaded.total_income).to eq(Money.brl("100.00"))
      expect(reloaded.total_expense).to eq(Money.brl("40.00"))
      expect(reloaded.balance).to eq(Money.brl("60.00"))
      expect(AccountabilityReportEntryRecord.where(accountability_report_id: saved.id).count).to eq(2)
    end

    it "percorre revisão e publicação sem reescrever as entradas" do
      income = posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      report = draft_report
      report.submit!(entries: [ snapshot(income, income_account) ], at: Time.utc(2026, 2, 1, 10))
      saved = report_repository.save(report, sync_entries: true)

      saved.start_review!(reviewer_id: user.id, at: Time.utc(2026, 2, 2, 9))
      report_repository.save(saved)

      saved.approve!(reviewer_id: user.id, opinion: "Documentação conferida", at: Time.utc(2026, 2, 3, 9))
      report_repository.save(saved)

      saved.publish!(at: Time.utc(2026, 2, 4, 9))
      published = report_repository.save(saved)

      reloaded = report_repository.find_published(published.id)
      expect(reloaded).to be_published
      expect(reloaded.entries.map(&:ledger_entry_id)).to eq([ income.id ])
      expect(reloaded.published_at).to eq(Time.utc(2026, 2, 4, 9))
    end

    it "não expõe rascunho na listagem pública" do
      report = draft_report
      saved = report_repository.save(report)

      expect(report_repository.find_published(saved.id)).to be_nil
      expect(report_repository.list_published(institution.id)).to be_empty
    end

    it "filtra a listagem pública por instituição e campanha" do
      income = posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      report = draft_report
      report.submit!(entries: [ snapshot(income, income_account) ], at: Time.utc(2026, 2, 1, 10))
      saved = report_repository.save(report, sync_entries: true)

      saved.start_review!(reviewer_id: user.id, at: Time.utc(2026, 2, 2, 9))
      report_repository.save(saved)
      saved.approve!(reviewer_id: user.id, opinion: "Ok", at: Time.utc(2026, 2, 3, 9))
      report_repository.save(saved)
      saved.publish!(at: Time.utc(2026, 2, 4, 9))
      report_repository.save(saved)

      expect(report_repository.list_published(institution.id).map(&:id)).to eq([ saved.id ])
      expect(report_repository.list_published(institution.id, campaign_id: campaign.id).map(&:id)).to eq([ saved.id ])
      expect(report_repository.list_published(other_institution.id)).to be_empty
      expect(report_repository.find_for_institution(id: saved.id, institution_id: other_institution.id)).to be_nil
    end

    it "deixa o banco recusar uma entrada de outro tenant" do
      income = posted_entry(kind: :income, amount: "100", account: income_account, campaign_id: campaign.id)
      report = draft_report
      report.submit!(entries: [ snapshot(income, income_account) ], at: Time.utc(2026, 2, 1, 10))
      saved = report_repository.save(report, sync_entries: true)

      other_account = account_repository.save(
        Account.build(institution_id: other_institution.id, code: "5.1", name: "Material", nature: :expense)
      )
      other_entry = LedgerEntryRecord.create!(
        institution_id: other_institution.id,
        account_id: other_account.id,
        kind: "expense",
        origin: "declared",
        amount_brl: 10,
        status: "posted",
        posted_on: Date.new(2026, 1, 10)
      )

      forged = AccountabilityReportEntryRecord.new(
        institution_id: other_institution.id,
        accountability_report_id: saved.id,
        ledger_entry_id: other_entry.id,
        account_id: other_account.id,
        kind: "expense",
        origin: "declared",
        account_code: other_account.code,
        account_name: other_account.name,
        posted_on: other_entry.posted_on,
        amount_brl: 10
      )

      expect { forged.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "FinancialSummary" do
    it "soma doação, receita declarada e despesa na mesma leitura" do
      donation = DonationRecord.create!(
        institution_id: institution.id,
        donor_name: "Doador",
        reference: "don_#{SecureRandom.hex(4)}",
        amount_brl: 100,
        payment_method: "pix",
        status: "received",
        received_at: Time.utc(2026, 1, 5, 12)
      )
      split = DonationSplitRecord.create!(
        donation_id: donation.id,
        institution_id: institution.id,
        recipient: "institution",
        percentage: 94,
        status: "done"
      )
      LedgerEntryRecord.create!(
        institution_id: institution.id,
        account_id: income_account.id,
        donation_split_id: split.id,
        kind: "income",
        origin: "donation",
        amount_brl: 94,
        status: "posted",
        posted_on: Date.new(2026, 1, 5)
      )
      posted_entry(kind: :income, amount: "50", account: income_account)
      posted_entry(kind: :expense, amount: "40", account: expense_account)

      summary = ledger_entry_repository.financial_summary(
        institution.id,
        from: period_start,
        to: period_end
      )

      expect(summary.donation_income).to eq(Money.brl("94.00"))
      expect(summary.declared_income).to eq(Money.brl("50.00"))
      expect(summary.expense).to eq(Money.brl("40.00"))
      expect(summary.total_income).to eq(Money.brl("144.00"))
      expect(summary.balance).to eq(Money.brl("104.00"))
    end

    it "aplica início e fim de período independentemente" do
      posted_entry(
        kind: :income,
        amount: "10",
        account: income_account,
        posted_on: Date.new(2026, 1, 5)
      )
      posted_entry(
        kind: :income,
        amount: "20",
        account: income_account,
        posted_on: Date.new(2026, 1, 20)
      )

      from_only = ledger_entry_repository.financial_summary(
        institution.id,
        from: Date.new(2026, 1, 10)
      )
      to_only = ledger_entry_repository.financial_summary(
        institution.id,
        to: Date.new(2026, 1, 10)
      )

      expect(from_only.declared_income).to eq(Money.brl("20.00"))
      expect(to_only.declared_income).to eq(Money.brl("10.00"))
    end

    it "recorta a campanha sem perder o resumo geral" do
      other_campaign = campaign_repository.save(
        Campaign.build(
          institution_id: institution.id,
          title: "Outra campanha",
          description: "Outra causa",
          goal: "5000",
          starts_on: period_start,
          ends_on: period_end
        )
      )
      posted_entry(kind: :income, amount: "10", account: income_account, campaign_id: campaign.id)
      posted_entry(kind: :income, amount: "90", account: income_account, campaign_id: other_campaign.id)

      scoped = ledger_entry_repository.financial_summary(
        institution.id,
        from: period_start,
        to: period_end,
        campaign_id: campaign.id
      )
      overall = ledger_entry_repository.financial_summary(
        institution.id,
        from: period_start,
        to: period_end
      )

      expect(scoped.declared_income).to eq(Money.brl("10.00"))
      expect(overall.declared_income).to eq(Money.brl("100.00"))
    end
  end

  describe "consultas públicas e vínculos" do
    it "encontra o perfil pelo slug" do
      saved = institution

      expect(institution_repository.find_by_slug("instituto-transparente").id).to eq(saved.id)
      expect(institution_repository.find_by_slug("inexistente")).to be_nil
      expect(saved).to be_public_profile_ready
    end

    it "filtra o feed por campanha" do
      with_campaign = post_repository.save(
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

      expect(post_repository.list_feed(institution.id, campaign_id: campaign.id).map(&:id))
        .to eq([ with_campaign.id ])
      expect(post_repository.list_feed(institution.id).size).to eq(2)
    end

    it "não deixa post apontar para campanha de outra instituição" do
      other_campaign = campaign_repository.save(
        Campaign.build(
          institution_id: other_institution.id,
          title: "Campanha alheia",
          description: "Outra",
          goal: "1000",
          starts_on: period_start,
          ends_on: period_end
        )
      )

      expect {
        post_repository.save(
          Post.build(
            institution_id: institution.id,
            campaign_id: other_campaign.id,
            title: "Post cruzado",
            content: "Conteúdo"
          )
        )
      }.to raise_error(ActiveRecord::RecordInvalid, /must belong to the same institution/)
    end

    it "lista apenas documentos marcados como públicos" do
      entry = posted_entry(kind: :expense, amount: "40", account: expense_account)
      public_document = document_repository.save(
        Document.build(
          institution_id: institution.id,
          target: DocumentTarget.for_ledger_entry(entry.id),
          kind: :nota_fiscal,
          public: true
        )
      )
      document_repository.save(
        Document.build(
          institution_id: institution.id,
          target: DocumentTarget.for_ledger_entry(entry.id),
          kind: :recibo
        )
      )

      docs = document_repository.list_public_for_attachable(
        institution_id: institution.id,
        attachable_type: DocumentTarget::LEDGER_ENTRY,
        attachable_id: entry.id
      )
      batch = document_repository.list_public_for_ledger_entries(
        institution_id: institution.id,
        ledger_entry_ids: [ entry.id ]
      )

      expect(docs.map(&:id)).to eq([ public_document.id ])
      expect(batch.map(&:id)).to eq([ public_document.id ])
    end

    it "busca conta por id somente dentro do tenant" do
      account = income_account

      expect(account_repository.find_by_id(institution_id: institution.id, id: account.id).code).to eq("4.1")
      expect(account_repository.find_by_id(institution_id: other_institution.id, id: account.id)).to be_nil
    end
  end

  describe "escrita multi-tenant nos repositórios" do
    it "não sobrescreve campanha de outra instituição" do
      other_campaign = campaign_repository.save(
        Campaign.build(
          institution_id: other_institution.id,
          title: "Campanha alheia",
          description: "Outra",
          goal: "1000",
          starts_on: period_start,
          ends_on: period_end
        )
      )
      forged = Campaign.build(
        institution_id: institution.id,
        id: other_campaign.id,
        title: "Campanha tomada",
        description: "Tentativa",
        goal: "1000",
        starts_on: period_start,
        ends_on: period_end
      )

      expect { campaign_repository.save(forged) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "não sobrescreve relatório de outra instituição" do
      other_report = report_repository.save(
        AccountabilityReport.build(
          institution_id: other_institution.id,
          title: "Relatório alheio",
          period_start: period_start,
          period_end: period_end
        )
      )
      forged = AccountabilityReport.build(
        institution_id: institution.id,
        id: other_report.id,
        title: "Relatório tomado",
        period_start: period_start,
        period_end: period_end
      )

      expect { report_repository.save(forged) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "não sobrescreve lançamento de outra instituição" do
      other_account = account_repository.save(
        Account.build(
          institution_id: other_institution.id,
          code: "5.1",
          name: "Material",
          nature: :expense
        )
      )
      other_entry = ledger_entry_repository.save(
        LedgerEntry.build(
          institution_id: other_institution.id,
          account_id: other_account.id,
          kind: :expense,
          amount: "10",
          status: :posted,
          posted_on: period_start
        )
      )
      forged = LedgerEntry.build(
        institution_id: institution.id,
        id: other_entry.id,
        account_id: expense_account.id,
        kind: :expense,
        amount: "10",
        status: :posted,
        posted_on: period_start
      )

      expect { ledger_entry_repository.save(forged) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "não sobrescreve post de outra instituição" do
      other_post = post_repository.save(
        Post.build(
          institution_id: other_institution.id,
          title: "Post alheio",
          content: "Conteúdo"
        )
      )
      forged = Post.build(
        institution_id: institution.id,
        id: other_post.id,
        title: "Post tomado",
        content: "Conteúdo"
      )

      expect { post_repository.save(forged) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "não sobrescreve documento de outra instituição" do
      other_account = account_repository.save(
        Account.build(
          institution_id: other_institution.id,
          code: "5.1",
          name: "Material",
          nature: :expense
        )
      )
      other_entry = ledger_entry_repository.save(
        LedgerEntry.build(
          institution_id: other_institution.id,
          account_id: other_account.id,
          kind: :expense,
          amount: "10",
          status: :posted,
          posted_on: period_start
        )
      )
      other_document = document_repository.save(
        Document.build(
          institution_id: other_institution.id,
          target: DocumentTarget.for_ledger_entry(other_entry.id),
          kind: :recibo
        )
      )
      entry = posted_entry(kind: :expense, amount: "10", account: expense_account)
      forged = Document.build(
        institution_id: institution.id,
        id: other_document.id,
        target: DocumentTarget.for_ledger_entry(entry.id),
        kind: :recibo
      )

      expect { document_repository.save(forged) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
