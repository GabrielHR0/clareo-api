require_relative "../../domain_helper"

RSpec.describe SplitPolicy do
  subject(:policy) { described_class.new }

  describe "tiered percentages" do
    it "charges more on small donations, where a flat provider fee bites hardest" do
      expect(policy.percentage_for("50.00")).to eq(Percentage.build(10))
    end

    it "steps down through the tiers" do
      expect(policy.percentage_for("75.00")).to eq(Percentage.build(6))
      expect(policy.percentage_for("200.00")).to eq(Percentage.build(4))
    end

    it "charges the lowest tier on large donations" do
      expect(policy.percentage_for("10000.00")).to eq(Percentage.build(2.5))
    end

    it "falls into the correct tier at an exact boundary" do
      expect(policy.percentage_for("100.00")).to eq(Percentage.build(6))
      expect(policy.percentage_for("100.01")).to eq(Percentage.build(4))
    end
  end

  describe "minimum donation" do
    it "exists because the provider charges a flat fee per charge" do
      expect(policy.minimum_donation).to eq(Money.brl("50.00"))
    end

    it "rejects amounts below it" do
      expect(policy).not_to be_accepts("49.99")
    end

    it "accepts the boundary" do
      expect(policy).to be_accepts("50.00")
    end
  end

  describe "configuration" do
    it "accepts custom tiers" do
      custom = described_class.new(
        tiers: [ { upto: Money.brl("100.00"), percentage: Percentage.build(3) }, { upto: nil, percentage: 1 } ],
        minimum_donation: "10.00"
      )

      expect(custom.percentage_for("50.00")).to eq(Percentage.build(3))
      expect(custom.minimum_donation).to eq(Money.brl("10.00"))
    end

    it "rejects an empty policy" do
      expect { described_class.new(tiers: []) }.to raise_error(InvalidSplit)
    end

    it "requires an open ended last tier" do
      expect { described_class.new(tiers: [ { upto: Money.brl("100.00"), percentage: 5 } ]) }
        .to raise_error(InvalidSplit)
    end

    it "rejects a zero tier percentage" do
      expect { described_class.new(tiers: [ { upto: nil, percentage: 0 } ]) }.to raise_error(InvalidSplit)
    end
  end

  it "reports itself for persistence" do
    expect(policy.to_h.first).to include(upto: "50.00", percentage: "10.0000")
  end
end
