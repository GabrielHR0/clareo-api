require_relative "../../domain_helper"

RSpec.describe Money do
  describe "construction" do
    it "normalizes to two decimals" do
      expect(described_class.brl("10.567").to_s).to eq("10.57")
    end

    it "rounds half up" do
      expect(described_class.brl("0.005").to_s).to eq("0.01")
    end

    it "accepts integers" do
      expect(described_class.brl(10).to_s).to eq("10.00")
    end

    it "is idempotent when given a money" do
      money = described_class.brl("10.00")

      expect(described_class.build(money)).to equal(money)
    end

    it "rejects unsupported types" do
      expect { described_class.build(:ten) }.to raise_error(ArgumentError)
    end
  end

  describe "arithmetic" do
    it "adds" do
      expect(described_class.brl("10.10") + described_class.brl("0.20")).to eq(described_class.brl("10.30"))
    end

    it "subtracts" do
      expect(described_class.brl("10.10") - described_class.brl("0.20")).to eq(described_class.brl("9.90"))
    end

    it "computes a percentage of itself" do
      result = described_class.brl("100.00").percentage_of(Percentage.build(6))

      expect(result).to eq(described_class.brl("6.00"))
    end

    it "computes a percentage against the net amount" do
      result = described_class.brl("98.01").percentage_of(Percentage.build(94))

      expect(result).to eq(described_class.brl("92.13"))
    end
  end

  describe "comparison" do
    it "sorts by amount" do
      sorted = [ described_class.brl("10.00"), described_class.brl("5.00") ].sort

      expect(sorted.map(&:to_s)).to eq(%w[5.00 10.00])
    end

    it "knows it is positive" do
      expect(described_class.brl("0.01")).to be_positive
    end

    it "knows it is zero" do
      expect(described_class.zero).to be_zero
    end
  end

  it "renders with two decimals" do
    expect(described_class.brl(7).to_s).to eq("7.00")
  end
end
