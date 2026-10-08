require_relative "../../domain_helper"

RSpec.describe Donation do
  let(:institution) do
    Institution.new(
      user_id: "user_1",
      id: "ins_1",
      legal_name: "Instituto Semear",
      settlement_strategy: :pix_payout,
      pix_key: "financeiro@institutosemear.org"
    )
  end

  let(:active_institution) do
    Institution.new(
      user_id: "user_1",
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

  def splits(institution_share: 94, platform_share: 6, target: institution)
    [
      DonationSplit.for_institution(institution: target, percentage: institution_share),
      DonationSplit.for_platform(percentage: platform_share)
    ]
  end

  def donation(**overrides)
    described_class.new(
      id: "don_1",
      institution: active_institution,
      donor_name: "Joao Silva",
      amount: "100.00",
      payment_method: :pix,
      reference: "don_1",
      splits: splits(target: active_institution),
      **overrides
    )
  end

  describe "amount" do
    it "must be positive" do
      expect { donation(amount: "0.00") }.to raise_error(InvalidDonation)
    end

    it "rejects a negative amount" do
      expect { donation(amount: "-1.00") }.to raise_error(InvalidDonation)
    end

    it "leaves the donation floor to policy, since tiers are a business decision" do
      expect(donation(amount: "0.01").amount).to eq(Money.brl("0.01"))
    end
  end

  describe "splits" do
    it "must total exactly one hundred percent" do
      expect { donation(splits: splits(institution_share: 90, platform_share: 6)) }
        .to raise_error(InvalidDonation, /exactly 100/)
    end

    it "rejects an empty split list" do
      expect { donation(splits: []) }.to raise_error(InvalidDonation)
    end

    it "rejects a list with no institution share" do
      expect { donation(splits: [ DonationSplit.for_platform(percentage: 100) ]) }
        .to raise_error(InvalidDonation)
    end
  end

  describe "institution eligibility" do
    it "refuses an institution that cannot accept donations" do
      expect { donation(institution: institution) }.to raise_error(InvalidDonation)
    end
  end

  describe "confirmation" do
    it "cannot come from creating the charge" do
      expect(donation).to be_pending
    end

    it "moves to received with the net amount reported by the provider" do
      record = donation

      expect { record.confirm_receipt!(asaas_payment_id: "pay_1", net_amount: "98.01", at: Time.now) }
        .to change(record, :status).from(:pending).to(:received)

      expect(record.net_amount).to eq(Money.brl("98.01"))
      expect(record.asaas_payment_id).to eq("pay_1")
    end

    it "refuses to confirm a refunded donation" do
      record = donation
      record.confirm_receipt!(asaas_payment_id: "pay_1", net_amount: "98.01", at: Time.now)
      record.refund!

      expect { record.confirm_receipt!(asaas_payment_id: "pay_1", net_amount: "98.01", at: Time.now) }
        .to raise_error(InvalidDonation)
    end
  end

  describe "split divergence" do
    it "blocks and can unblock" do
      record = donation

      expect { record.block_split! }.to change(record, :status).to(:split_blocked)
      expect { record.unblock_split! }.to change(record, :status).to(:pending)
    end

    it "can be blocked even after receipt, because the provider blocks at settlement" do
      record = donation
      record.confirm_receipt!(asaas_payment_id: "pay_1", net_amount: "98.01", at: Time.now)

      expect { record.block_split! }.to change(record, :status).to(:split_blocked)
    end
  end

  describe "routable splits" do
    it "omits the platform share because the provider rejects the issuing wallet" do
      expect(donation.routable_splits.map(&:recipient)).to eq([ :institution ])
    end
  end
end
