require_relative "../../domain_helper"

RSpec.describe AccountTemplate do
  let(:institution_id) { 7 }

  describe "the catalogue" do
    it "covers both natures, because a ledger without both is not a ledger" do
      natures = described_class.default.map { |spec| spec[:nature] }

      expect(natures).to include(:income)
      expect(natures).to include(:expense)
    end

    it "has unique codes, because the code is the identity within the institution" do
      codes = described_class.default.map { |spec| spec[:code] }

      expect(codes.uniq.size).to eq(codes.size)
    end

    it "points every parent at an existing account" do
      codes = described_class.default.map { |spec| spec[:code] }

      described_class.default.each do |spec|
        next if spec[:parent_code].nil?

        expect(codes).to include(spec[:parent_code]),
          "conta #{spec[:code]} aponta para um pai que não existe: #{spec[:parent_code]}"
      end
    end

    it "has no cycle, because a self reference would be caught only at runtime" do
      by_code = described_class.default.to_h { |spec| [ spec[:code], spec[:parent_code] ] }

      described_class.default.map { |spec| spec[:code] }.each do |code|
        seen = []
        cursor = by_code[code]

        while cursor
          raise "ciclo em #{code} via #{cursor}" if seen.include?(cursor)

          seen << cursor
          cursor = by_code[cursor]
        end
      end
    end
  end

  describe "the donation income anchor" do
    # A receita automática do split aponta para esta conta por código. Se ela
    # não for system, ou não for de receita, a conciliação perde a âncora.
    it "exists, is a system account, and is income" do
      expect(described_class.donation_income?).to be(true)
    end

    it "is built as a system income account" do
      anchor = described_class.build_for(institution_id: institution_id).find do |account|
        account.code == described_class::DONATION_INCOME_CODE
      end

      expect(anchor).not_to be_nil
      expect(anchor).to be_income
      expect(anchor.system).to be(true)
      expect(anchor).not_to be_deactivatable
    end
  end

  describe "build_for" do
    it "builds every account bound to the tenant" do
      accounts = described_class.build_for(institution_id: institution_id)

      expect(accounts.size).to eq(described_class.default.size)
      expect(accounts.map(&:institution_id).uniq).to eq([ institution_id ])
    end

    it "filters by nature when asked" do
      expenses = described_class.build_for(institution_id: institution_id, nature: :expense)

      expect(expenses).to all(be_expense)
      expect(expenses).not_to be_empty
    end
  end
end
