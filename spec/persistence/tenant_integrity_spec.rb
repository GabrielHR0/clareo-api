require "rails_helper"

RSpec.describe "integridade multi-tenant no banco" do
  let(:user) do
    UserRecord.create!(
      email: "tenant-#{SecureRandom.hex(4)}@exemplo.com",
      name: "Admin",
      role: "platform_admin",
      password: "senha-de-teste-123"
    )
  end

  let(:institution) do
    InstitutionRecord.create!(
      user_id: user.id,
      legal_name: "Instituto A",
      settlement_strategy: "pix_payout",
      pix_key: "a@exemplo.org",
      status: "active",
      slug: "tenant-a-#{SecureRandom.hex(3)}"
    )
  end

  let(:other_institution) do
    InstitutionRecord.create!(
      user_id: user.id,
      legal_name: "Instituto B",
      settlement_strategy: "pix_payout",
      pix_key: "b@exemplo.org",
      status: "active",
      slug: "tenant-b-#{SecureRandom.hex(3)}"
    )
  end

  let(:account) do
    AccountRecord.create!(
      institution_id: institution.id,
      code: "4.1",
      name: "Receitas",
      nature: "income"
    )
  end

  let(:other_account) do
    AccountRecord.create!(
      institution_id: other_institution.id,
      code: "4.1",
      name: "Receitas",
      nature: "income"
    )
  end

  let(:cost_center) do
    CostCenterRecord.create!(
      institution_id: institution.id,
      code: "cc-a",
      name: "Centro A"
    )
  end

  let(:other_cost_center) do
    CostCenterRecord.create!(
      institution_id: other_institution.id,
      code: "cc-b",
      name: "Centro B"
    )
  end

  let(:campaign) do
    CampaignRecord.create!(
      institution_id: institution.id,
      title: "Campanha A",
      description: "Campanha da instituição A",
      goal_brl: 1000,
      starts_on: Date.new(2026, 1, 1),
      ends_on: Date.new(2026, 1, 31)
    )
  end

  let(:other_campaign) do
    CampaignRecord.create!(
      institution_id: other_institution.id,
      title: "Campanha B",
      description: "Campanha da instituição B",
      goal_brl: 1000,
      starts_on: Date.new(2026, 1, 1),
      ends_on: Date.new(2026, 1, 31)
    )
  end

  let(:donation) do
    DonationRecord.create!(
      institution_id: institution.id,
      donor_name: "Doador A",
      reference: "don-a-#{SecureRandom.hex(3)}",
      amount_brl: 100,
      payment_method: "pix",
      status: "received"
    )
  end

  let(:other_donation) do
    DonationRecord.create!(
      institution_id: other_institution.id,
      donor_name: "Doador B",
      reference: "don-b-#{SecureRandom.hex(3)}",
      amount_brl: 100,
      payment_method: "pix",
      status: "received"
    )
  end

  let(:other_split) do
    DonationSplitRecord.create!(
      donation_id: other_donation.id,
      institution_id: other_institution.id,
      recipient: "institution",
      percentage: 94,
      status: "done"
    )
  end

  let(:ledger_entry) do
    LedgerEntryRecord.create!(
      institution_id: institution.id,
      account_id: account.id,
      cost_center_id: cost_center.id,
      campaign_id: campaign.id,
      kind: "expense",
      origin: "declared",
      amount_brl: 10,
      status: "posted",
      posted_on: Date.new(2026, 1, 10)
    )
  end

  let(:other_ledger_entry) do
    LedgerEntryRecord.create!(
      institution_id: other_institution.id,
      account_id: other_account.id,
      cost_center_id: other_cost_center.id,
      campaign_id: other_campaign.id,
      kind: "expense",
      origin: "declared",
      amount_brl: 10,
      status: "posted",
      posted_on: Date.new(2026, 1, 10)
    )
  end

  let(:other_post) do
    PostRecord.create!(
      institution_id: other_institution.id,
      campaign_id: other_campaign.id,
      title: "Post B",
      content: "Conteúdo B"
    )
  end

  let(:report) do
    AccountabilityReportRecord.create!(
      institution_id: institution.id,
      campaign_id: campaign.id,
      title: "Relatório A",
      period_start: Date.new(2026, 1, 1),
      period_end: Date.new(2026, 1, 31)
    )
  end

  let(:other_report) do
    AccountabilityReportRecord.create!(
      institution_id: other_institution.id,
      campaign_id: other_campaign.id,
      title: "Relatório B",
      period_start: Date.new(2026, 1, 1),
      period_end: Date.new(2026, 1, 31)
    )
  end

  def expect_foreign_key_violation(&block)
    expect(&block).to raise_error(ActiveRecord::InvalidForeignKey)
  end

  describe "lançamentos" do
    it "recusa conta de outra instituição" do
      entry = LedgerEntryRecord.new(
        institution_id: institution.id,
        account_id: other_account.id,
        kind: "expense",
        origin: "declared",
        amount_brl: 10,
        status: "posted",
        posted_on: Date.new(2026, 1, 10)
      )

      expect_foreign_key_violation { entry.save!(validate: false) }
    end

    it "recusa centro de custo de outra instituição" do
      entry = LedgerEntryRecord.new(
        institution_id: institution.id,
        account_id: account.id,
        cost_center_id: other_cost_center.id,
        kind: "expense",
        origin: "declared",
        amount_brl: 10,
        status: "posted",
        posted_on: Date.new(2026, 1, 10)
      )

      expect_foreign_key_violation { entry.save!(validate: false) }
    end

    it "recusa campanha de outra instituição" do
      entry = LedgerEntryRecord.new(
        institution_id: institution.id,
        account_id: account.id,
        campaign_id: other_campaign.id,
        kind: "expense",
        origin: "declared",
        amount_brl: 10,
        status: "posted",
        posted_on: Date.new(2026, 1, 10)
      )

      expect_foreign_key_violation { entry.save!(validate: false) }
    end

    it "recusa split de outra instituição" do
      entry = LedgerEntryRecord.new(
        institution_id: institution.id,
        account_id: account.id,
        donation_split_id: other_split.id,
        kind: "income",
        origin: "donation",
        amount_brl: 94,
        status: "posted",
        posted_on: Date.new(2026, 1, 10)
      )

      expect_foreign_key_violation { entry.save!(validate: false) }
    end
  end

  describe "doações, splits e repasses" do
    it "recusa doação com campanha de outra instituição" do
      forged = DonationRecord.new(
        institution_id: institution.id,
        campaign_id: other_campaign.id,
        donor_name: "Doador",
        reference: "forged-#{SecureRandom.hex(3)}",
        amount_brl: 10,
        payment_method: "pix",
        status: "received"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa split com doação de outra instituição" do
      forged = DonationSplitRecord.new(
        donation_id: other_donation.id,
        institution_id: institution.id,
        recipient: "institution",
        percentage: 50,
        status: "done"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa repasse com doação de outra instituição" do
      forged = PayoutRecord.new(
        institution_id: institution.id,
        donation_id: other_donation.id,
        amount_brl: 10,
        pix_key: "a@exemplo.org",
        status: "pending"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end
  end

  describe "documentos e posts" do
    it "recusa documento com lançamento de outra instituição" do
      forged = DocumentRecord.new(
        institution_id: institution.id,
        attachable_type: "LedgerEntry",
        ledger_entry_id: other_ledger_entry.id,
        kind: "recibo"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa documento com post de outra instituição" do
      forged = DocumentRecord.new(
        institution_id: institution.id,
        attachable_type: "Post",
        post_id: other_post.id,
        kind: "recibo"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa post com campanha de outra instituição" do
      forged = PostRecord.new(
        institution_id: institution.id,
        campaign_id: other_campaign.id,
        title: "Post",
        content: "Conteúdo"
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end
  end

  describe "prestação de contas" do
    it "recusa relatório com campanha de outra instituição" do
      forged = AccountabilityReportRecord.new(
        institution_id: institution.id,
        campaign_id: other_campaign.id,
        title: "Relatório",
        period_start: Date.new(2026, 1, 1),
        period_end: Date.new(2026, 1, 31)
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa snapshot com conta de outra instituição" do
      forged = AccountabilityReportEntryRecord.new(
        institution_id: institution.id,
        accountability_report_id: report.id,
        ledger_entry_id: ledger_entry.id,
        account_id: other_account.id,
        campaign_id: campaign.id,
        kind: "expense",
        origin: "declared",
        account_code: other_account.code,
        account_name: other_account.name,
        posted_on: ledger_entry.posted_on,
        amount_brl: 10
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end

    it "recusa snapshot com campanha de outra instituição" do
      forged = AccountabilityReportEntryRecord.new(
        institution_id: institution.id,
        accountability_report_id: report.id,
        ledger_entry_id: ledger_entry.id,
        account_id: account.id,
        campaign_id: other_campaign.id,
        kind: "expense",
        origin: "declared",
        account_code: account.code,
        account_name: account.name,
        posted_on: ledger_entry.posted_on,
        amount_brl: 10
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end
  end

  describe "plano de contas" do
    it "recusa conta com pai de outra instituição" do
      other_parent = AccountRecord.create!(
        institution_id: other_institution.id,
        code: "9",
        name: "Despesas",
        nature: "expense"
      )

      forged = AccountRecord.new(
        institution_id: institution.id,
        code: "9.1",
        name: "Despesas administrativas",
        nature: "expense",
        parent_code: other_parent.code
      )

      expect_foreign_key_violation { forged.save!(validate: false) }
    end
  end
end
