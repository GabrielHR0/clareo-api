require_relative "../../domain_helper"

RSpec.describe Plan do
  def plan(**overrides)
    described_class.build(code: :pro, name: "Pro", price: "97.00", **overrides)
  end

  it "defaults to unlimited institutions" do
    expect(plan(max_institutions: nil)).to be_unlimited_institutions
  end

  it "permits another institution below the limit" do
    expect(plan(max_institutions: 5).allows?(4)).to be(true)
  end

  it "refuses another institution at the limit" do
    expect(plan(max_institutions: 5).allows?(5)).to be(false)
  end

  it "never reports negative remaining slots" do
    expect(plan(max_institutions: 5).remaining_slots(7)).to eq(0)
  end

  it "knows it is free" do
    expect(plan(code: :free, price: "0")).to be_free
  end

  it "rejects an unknown tier" do
    expect { plan(code: :enterprise_plus) }.to raise_error(InvalidSubscription)
  end

  it "rejects a non-positive institution limit" do
    expect { plan(max_institutions: 0) }.to raise_error(InvalidSubscription)
  end
end
