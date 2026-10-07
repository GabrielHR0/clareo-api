require_relative "../../domain_helper"

RSpec.describe Institution do
  let(:address) do
    Address.build(
      street: "Rua Fernando Orlandi",
      number: "544",
      neighborhood: "Jardim Pedra Branca",
      postal_code: "14079-452",
      city: "Ribeirão Preto"
    )
  end

  def subaccount(**overrides)
    described_class.new(
      id: "ins_1",
      legal_name: "Instituto Semear",
      settlement_strategy: :subaccount,
      cnpj: "66625514000140",
      legal_entity_kind: :ltda,
      declared_monthly_revenue: "50000",
      contact_email: "financeiro@institutosemear.org",
      mobile_phone: "11988887777",
      address: address,
      **overrides
    )
  end

  def pix_payout(**overrides)
    described_class.new(
      id: "ins_2",
      legal_name: "Criador de Conteudo",
      settlement_strategy: :pix_payout,
      cnpj: "52998224725",
      legal_entity_kind: nil,
      pix_key: "financeiro@criador.com",
      **overrides
    )
  end

  describe "subaccount strategy" do
    it "requires a cnpj" do
      expect { subaccount(cnpj: nil) }.to raise_error(InvalidInstitution)
    end

    it "requires a declared monthly revenue because the provider demands it" do
      expect { subaccount(declared_monthly_revenue: nil) }.to raise_error(InvalidInstitution)
    end

    it "requires a complete address because the provider derives the city from it" do
      expect { subaccount(address: nil) }.to raise_error(InvalidInstitution)
    end

    it "accepts an association, which is how ongs are represented" do
      expect(subaccount(legal_entity_kind: :association).legal_entity_kind).to eq(:association)
    end

    it "rejects an unknown legal entity kind" do
      expect { subaccount(legal_entity_kind: :cooperative) }.to raise_error(InvalidInstitution)
    end
  end

  describe "pix_payout strategy" do
    it "requires a pix key" do
      expect { pix_payout(pix_key: nil) }.to raise_error(InvalidInstitution)
    end

    it "does not require provider onboarding data" do
      expect(pix_payout.declared_monthly_revenue).to be_nil
    end
  end

  describe "strategy is fixed" do
    it "does not expose a way to change it" do
      expect(described_class.instance_methods).not_to include(:settlement_strategy=)
      expect(described_class.instance_methods.grep(/change_settlement/)).to be_empty
    end
  end

  describe "accepts_donations?" do
    it "is false for a draft" do
      expect(subaccount).not_to be_accepts_donations
    end

    it "is false once active but not yet bound to the provider" do
      institution = subaccount(status: :active)

      expect(institution).not_to be_accepts_donations
    end

    it "is false once bound but not approved by the provider" do
      institution = subaccount.tap { |record| record.submit_for_approval! }
        .bind_provider!(account_id: "acc_1", wallet_id: "wal_1")

      expect(institution).not_to be_accepts_donations
    end

    it "is true once bound and approved" do
      institution = subaccount.submit_for_approval!.bind_provider!(account_id: "acc_1", wallet_id: "wal_1")
      institution.approve_registration!

      expect(institution).to be_accepts_donations
    end

    it "is true for pix_payout institutions without any provider binding" do
      institution = pix_payout(status: :active)

      expect(institution).to be_accepts_donations
    end
  end

  describe "status transitions" do
    it "walks draft to active" do
      institution = subaccount

      expect { institution.submit_for_approval! }.to change(institution, :status).from(:draft).to(:pending_approval)

      institution.bind_provider!(account_id: "acc_1", wallet_id: "wal_1")

      expect { institution.approve_registration! }.to change(institution, :status).to(:active)
      expect(institution).to be_registration_approved
    end

    it "refuses to skip the approval step" do
      institution = subaccount(status: :active)
      institution.bind_provider!(account_id: "acc_1", wallet_id: "wal_1")

      expect { institution.approve_registration! }.to raise_error(InvalidInstitution)
    end

    it "blocks a pending institution on rejection" do
      institution = subaccount.submit_for_approval!

      expect { institution.reject_registration! }.to change(institution, :status).to(:blocked)
      expect(institution.registration_status).to eq(:rejected)
    end

    it "can be blocked from active" do
      institution = subaccount(status: :active)

      expect { institution.block! }.to change(institution, :status).to(:blocked)
    end
  end

  describe "withdrawal responsibility" do
    it "is the institution's own job on the subaccount path" do
      expect(subaccount.withdraws_on_its_own?).to be(true)
    end

    it "is the platform's job on the pix_payout path" do
      expect(pix_payout.withdraws_on_its_own?).to be(false)
    end
  end
end
