require_relative "../../domain_helper"

RSpec.describe Plan do
  let(:free) { described_class.build(code: :free, name: "Básico", price: "0") }
  let(:pro) { described_class.build(code: :pro, name: "Pro", price: "97.00") }

  it "carries price and presentation" do
    expect(pro.price).to eq(Money.brl("97.00"))
    expect(pro.name).to eq("Pro")
  end

  it "recognises the free plan by price, not by code" do
    expect(free.free?).to be(true)
    expect(pro.free?).to be(false)
  end

  it "does not carry an institution quota, because the plan is per institution" do
    expect(described_class.instance_methods).not_to include(:allows?, :remaining_slots, :unlimited_institutions?)
  end

  it "keeps features as presentation only, never as a gate" do
    plan = described_class.build(code: :pro, name: "Pro", price: "97.00", features: [ "Transparência" ])

    expect(plan.features).to eq([ "Transparência" ])
    expect(described_class.instance_methods).not_to include(:allows_feature?)
  end

  describe "invariants" do
    it "refuses a tier outside the catalogue" do
      expect { described_class.build(code: :gold, name: "Gold", price: "1") }
        .to raise_error(InvalidSubscription, /plan code must be one of/)
    end

    it "refuses a negative price" do
      expect { described_class.build(code: :pro, name: "Pro", price: "-1") }
        .to raise_error(InvalidSubscription, /price cannot be negative/)
    end

    it "requires a name" do
      expect { described_class.build(code: :pro, name: "  ", price: "1") }
        .to raise_error(InvalidSubscription, /name cannot be blank/)
    end
  end
end
