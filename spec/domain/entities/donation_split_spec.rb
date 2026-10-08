require_relative "../../domain_helper"

RSpec.describe DonationSplit do
  let(:institution) do
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
    )
  end

  it "requires an institution on an institution split" do
    expect { described_class.new(recipient: :institution, percentage: 94) }
      .to raise_error(InvalidSplit)
  end

  it "refuses an institution on a platform split, since it stays on the issuing account" do
    expect { described_class.new(recipient: :platform, percentage: 6, institution: institution) }
      .to raise_error(InvalidSplit)
  end

  it "rejects a zero percentage, which would silently vanish from the split" do
    expect { described_class.for_platform(percentage: 0) }.to raise_error(InvalidSplit)
  end

  it "marks only institution shares as routable" do
    expect(described_class.for_platform(percentage: 6)).not_to be_routable
    expect(described_class.for_institution(institution: institution, percentage: 94)).to be_routable
  end

  describe "entitlement" do
    it "is only computable once the net amount is known" do
      split = described_class.for_institution(institution: institution, percentage: 94)

      expect(split.entitlement_of("98.01")).to eq(Money.brl("92.13"))
    end
  end

  describe "provider outcome" do
    it "records the settled value reported by the webhook" do
      split = described_class.for_institution(institution: institution, percentage: 94)

      split.mark_done!(total_value: "92.13", asaas_split_id: "spl_1")

      expect(split).to be_done
      expect(split.total_value).to eq(Money.brl("92.13"))
      expect(split.asaas_split_id).to eq("spl_1")
    end

    it "records a divergence block" do
      split = described_class.for_platform(percentage: 6)

      split.block!

      expect(split).to be_blocked
      expect(split.cancellation_reason).to eq(:value_divergence_block)
    end
  end

  describe "transition guards" do
    it "confirms a blocked split once the divergence is resolved" do
      split = described_class.for_platform(percentage: 6)
      split.block!

      split.mark_done!(total_value: "92.13")

      expect(split).to be_done
    end

    it "refuses to settle an already cancelled split" do
      split = described_class.for_platform(percentage: 6)
      split.cancel!(reason: :payment_refunded)

      expect { split.mark_done!(total_value: "92.13") }
        .to raise_error(InvalidSplit, /from cancelled to done/)
    end

    it "refuses to cancel a settled split" do
      split = described_class.for_platform(percentage: 6)
      split.mark_done!(total_value: "92.13")

      expect { split.cancel! }.to raise_error(InvalidSplit, /from done to cancelled/)
    end

    it "refuses to settle a settled split twice" do
      split = described_class.for_platform(percentage: 6)
      split.mark_done!(total_value: "92.13")

      expect { split.mark_done!(total_value: "92.13") }
        .to raise_error(InvalidSplit, /from done to done/)
    end

    it "refuses to block a cancelled split" do
      split = described_class.for_platform(percentage: 6)
      split.cancel!(reason: :wallet_unable_to_receive)

      expect { split.block! }.to raise_error(InvalidSplit, /from cancelled to blocked/)
    end

    it "refuses a cancellation reason outside the known set" do
      split = described_class.for_platform(percentage: 6)

      expect { split.cancel!(reason: :invented_by_the_caller) }
        .to raise_error(InvalidSplit, /reason must be one of/)
    end
  end
end
