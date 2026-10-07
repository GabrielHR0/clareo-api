require_relative "../../domain_helper"

RSpec.describe Address do
  def build(**overrides)
    described_class.build(
      street: "Rua Fernando Orlandi",
      number: "544",
      neighborhood: "Jardim Pedra Branca",
      postal_code: "14079452",
      **overrides
    )
  end

  it "formats the postal code" do
    expect(build.postal_code).to eq("14079-452")
  end

  it "accepts an already formatted postal code" do
    expect(build(postal_code: "14079-452").postal_code).to eq("14079-452")
  end

  it "rejects a postal code with the wrong digit count" do
    expect { build(postal_code: "1407945") }.to raise_error(InvalidInstitution)
  end

  it "rejects a blank street" do
    expect { build(street: "  ") }.to raise_error(InvalidInstitution)
  end

  it "rejects a blank number" do
    expect { build(number: nil) }.to raise_error(InvalidInstitution)
  end

  it "rejects a blank neighborhood" do
    expect { build(neighborhood: "") }.to raise_error(InvalidInstitution)
  end

  it "normalizes optional fields to nil instead of empty strings" do
    expect(build(complement: "  ", city: nil).to_h).to include(complement: nil, city: nil)
  end

  it "compares by value" do
    expect(build).to eq(build)
  end
end
