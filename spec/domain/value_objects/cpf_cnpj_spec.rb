require_relative "../../domain_helper"

RSpec.describe CpfCnpj do
  describe "CPF" do
    it "accepts a valid cpf" do
      expect(described_class.new("529.982.247-25")).to be_cpf
    end

    it "strips punctuation" do
      expect(described_class.new("529.982.247-25").digits).to eq("52998224725")
    end

    it "formats back" do
      expect(described_class.new("52998224725").formatted).to eq("529.982.247-25")
    end

    it "rejects a wrong check digit" do
      expect { described_class.new("52998224726") }.to raise_error(InvalidInstitution)
    end

    it "rejects repeated digits" do
      expect { described_class.new("11111111111") }.to raise_error(InvalidInstitution)
    end
  end

  describe "CNPJ" do
    it "accepts a valid cnpj" do
      expect(described_class.new("66625514000140")).to be_cnpj
    end

    it "accepts a zeroed cnpj check digit pair" do
      expect(described_class.new("11222333000181")).to be_cnpj
    end

    it "rejects a wrong check digit" do
      expect { described_class.new("66625514000141") }.to raise_error(InvalidInstitution)
    end

    it "rejects repeated digits" do
      expect { described_class.new("11111111111111") }.to raise_error(InvalidInstitution)
    end

    it "formats back" do
      expect(described_class.new("66625514000140").formatted).to eq("66.625.514/0001-40")
    end
  end

  it "rejects a length that is neither cpf nor cnpj" do
    expect { described_class.new("1234567890") }.to raise_error(InvalidInstitution)
  end
end
