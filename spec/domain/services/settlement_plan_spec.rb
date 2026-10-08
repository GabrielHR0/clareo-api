require_relative "../../domain_helper"

RSpec.describe SettlementPlan do
  let(:subaccount_institution) do
    Institution.new(
      id: "ins_1",
      legal_name: "Instituto Semear",
      settlement_strategy: :subaccount,
      cnpj: "66625514000140",
      legal_entity_kind: :ltda,
      declared_monthly_revenue: "50000",
      contact_email: "financeiro@institutosemear.org",
      mobile_phone: "11988887777",
      address: Address.build(
        street: "Rua Fernando Orlandi", number: "544",
        neighborhood: "Jardim Pedra Branca", postal_code: "14079-452"
      )
    ).tap do |record|
      record.submit_for_approval!
      record.bind_provider!(account_id: "acc_1", wallet_id: "wal_1")
      record.approve_registration!
    end
  end

  let(:pix_payout_institution) do
    Institution.new(
      id: "ins_2",
      legal_name: "Criador de Conteudo",
      settlement_strategy: :pix_payout,
      pix_key: "financeiro@criador.com",
      status: :active
    )
  end

  it "always totals one hundred percent" do
    plan = described_class.call(institution: subaccount_institution, amount: "100.00")

    expect(Percentage.sum(plan.map(&:percentage))).to be_full
  end

  it "gives the platform the tiered share" do
    plan = described_class.call(institution: subaccount_institution, amount: "100.00")
    platform = plan.find { |split| split.recipient == :platform }

    expect(platform.percentage).to eq(Percentage.build(6))
  end

  it "complements the institution share" do
    plan = described_class.call(institution: subaccount_institution, amount: "100.00")
    institution_split = plan.find { |split| split.recipient == :institution }

    expect(institution_split.percentage).to eq(Percentage.build(94))
  end

  it "applies the same economics to both strategies, only the mechanism differs" do
    via_subaccount = described_class.call(institution: subaccount_institution, amount: "100.00")
    via_pix = described_class.call(institution: pix_payout_institution, amount: "100.00")

    expect(via_pix.map(&:percentage)).to eq(via_subaccount.map(&:percentage))
  end

  it "routes only the institution share, since the platform stays on the issuing account" do
    plan = described_class.call(institution: subaccount_institution, amount: "100.00")

    expect(plan.select(&:routable?)).to all(have_attributes(recipient: :institution))
  end

  it "accepts a custom policy" do
    policy = SplitPolicy.new(
      tiers: [ { upto: nil, percentage: 3 } ],
      minimum_donation: "10.00"
    )

    plan = described_class.call(institution: subaccount_institution, amount: "100.00", policy: policy)

    expect(plan.find { |split| split.recipient == :platform }.percentage).to eq(Percentage.build(3))
  end

  it "refuses an institution that cannot accept donations" do
    draft = Institution.new(
      id: "ins_3", legal_name: "Novo", settlement_strategy: :pix_payout, pix_key: "a@b.com"
    )

    expect { described_class.call(institution: draft, amount: "100.00") }.to raise_error(InvalidDonation)
  end

  it "refuses an amount below the policy minimum" do
    expect { described_class.call(institution: subaccount_institution, amount: "10.00") }
      .to raise_error(InvalidDonation)
  end
end
