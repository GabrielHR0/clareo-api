require_relative "../../domain_helper"

RSpec.describe ExternalReference do
  it "trims the value" do
    expect(described_class.new("  donation-1  ").to_s).to eq("donation-1")
  end

  it "rejects a blank reference" do
    expect { described_class.new("  ") }.to raise_error(InvalidDonation)
  end

  it "rejects a reference longer than the provider accepts" do
    expect { described_class.new("a" * 51) }.to raise_error(InvalidDonation)
  end

  it "rejects whitespace inside the reference" do
    expect { described_class.new("donation 1") }.to raise_error(InvalidDonation)
  end

  it "accepts exactly fifty characters" do
    expect(described_class.new("a" * 50).to_s.length).to eq(50)
  end
end
