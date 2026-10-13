require_relative "../../domain_helper"

RSpec.describe Account do
  def account(**overrides)
    described_class.build(
      institution_id: "ins_1",
      code: "5.1",
      name: "Material de Consumo",
      nature: :expense,
      **overrides
    )
  end

  it "carries classification, which is what turns an expense into accountability" do
    expect(account.code).to eq("5.1")
    expect(account.nature).to eq(:expense)
    expect(account).to be_expense
  end

  it "distinguishes income from expense" do
    expect(account(nature: :income)).to be_income
  end

  it "normalizes the code, because the institution types it" do
    expect(account(code: "  5 . 1  ").code).to eq("5.1")
  end

  it "is identified by institution plus code, not by name" do
    expect(account).to eq(described_class.build(
      institution_id: "ins_1", code: "5.1", name: "Outro Nome", nature: :expense
    ))
  end

  describe "hierarchy" do
    it "points at the parent by code, not by id, so the catalogue stays pure data" do
      expect(account(parent_code: "5").parent_code).to eq("5")
    end

    it "refuses to be its own parent" do
      expect { account(parent_code: "5.1") }
        .to raise_error(InvalidAccount, /cannot be its own parent/)
    end

    it "accepts no parent, because a top level account is valid" do
      expect(account.parent_code).to be_nil
    end
  end

  describe "system accounts" do
    it "cannot be deactivated, because the donation income points at one by code" do
      expect(account(system: true)).not_to be_deactivatable
      expect(account(system: false)).to be_deactivatable
    end
  end

  describe "invariants" do
    it "requires an institution, because the plan of accounts belongs to the tenant" do
      expect { account(institution_id: nil) }
        .to raise_error(InvalidAccount, /institution is required/)
    end

    it "requires a code" do
      expect { account(code: "  ") }.to raise_error(InvalidAccount, /code cannot be blank/)
    end

    it "requires a name" do
      expect { account(name: "") }.to raise_error(InvalidAccount, /name cannot be blank/)
    end

    it "refuses a nature outside the closed set" do
      expect { account(nature: :equity) }
        .to raise_error(InvalidAccount, /nature must be one of income, expense/)
    end
  end
end
