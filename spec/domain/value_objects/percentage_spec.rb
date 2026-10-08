require_relative "../../domain_helper"

RSpec.describe Percentage do
  it "normalizes to four decimals" do
    expect(described_class.build("12.34567").to_s).to eq("12.3457")
  end

  it "accepts a percentage as itself" do
    percentage = described_class.build(50)

    expect(described_class.build(percentage)).to equal(percentage)
  end

  it "rejects negative values" do
    expect { described_class.build(-1) }.to raise_error(InvalidSplit)
  end

  it "rejects values above one hundred" do
    expect { described_class.build(100.01) }.to raise_error(InvalidSplit)
  end

  it "accepts exactly one hundred" do
    expect(described_class.build(100)).to be_full
  end

  it "sums to exactly one hundred across the tiers of a split" do
    total = described_class.sum([ described_class.build(94), described_class.build(6) ])

    expect(total).to be_full
  end

  it "exposes the complement used to complete a split" do
    expect(described_class.build(6).complement.to_s).to eq("94.0000")
  end

  it "subtracts" do
    expect(described_class.build(100) - described_class.build(6.5)).to eq(described_class.build(93.5))
  end
end
