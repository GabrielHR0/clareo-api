require_relative "../../domain_helper"

RSpec.describe PixKey do
  it "strips whitespace" do
    expect(described_class.new(" 529.982.247-25 ").value).to eq("529.982.247-25")
  end

  it "rejects a blank key" do
    expect { described_class.new("   ") }.to raise_error(InvalidInstitution)
  end

  it "detects an email key" do
    expect(described_class.new("joao@example.com").type).to eq(:email)
  end

  it "detects a cpf key" do
    expect(described_class.new("52998224725")).to be_cpf
  end

  it "detects a cnpj key" do
    expect(described_class.new("66625514000140")).to be_cnpj
  end

  it "detects a random key" do
    expect(described_class.new("7b5e4e2c-1a3d-4f6b-8c9e-0d1f2a3b4c5d")).to be_random
  end

  it "falls back to phone for anything else" do
    expect(described_class.new("+5511999999999").type).to eq(:phone)
  end

  it "does not raise for an unrecognised format, leaving validation to the provider" do
    expect { described_class.new("not-a-known-format") }.not_to raise_error
  end
end
