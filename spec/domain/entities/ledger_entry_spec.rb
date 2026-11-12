require_relative "../../domain_helper"

RSpec.describe LedgerEntry do
  let(:account_id) { 11 }
  let(:split_id) { 77 }

  def entry(**overrides)
    described_class.build(
      institution_id: "ins_1",
      kind: :expense,
      amount: "120.00",
      description: "Material de consumo",
      account_id: account_id,
      **overrides
    )
  end

  describe "who owns the number" do
    # A regra que sustenta a transparência auditável: a receita é fato do
    # sistema, a despesa é declaração da instituição.
    it "a despesa é declaração da instituição" do
      expect(entry).to be_declared
      expect(entry).not_to be_system
      expect(entry).to be_editable
    end

    it "a receita do split é do sistema e nasce postada" do
      system = described_class.from_donation_split(
        institution_id: "ins_1", donation_split_id: split_id,
        account_id: account_id, amount: "92.13", posted_on: Date.new(2026, 4, 1)
      )

      expect(system).to be_system
      expect(system).to be_income
      expect(system).to be_posted
      expect(system).not_to be_editable
      expect(system.donation_split_id).to eq(split_id)
    end

    it "recusa despesa com split, porque split é só receita" do
      expect { entry(donation_split_id: split_id) }
        .to raise_error(InvalidLedgerEntry, /donation_split_id is only allowed on donation entries/)
    end

    it "recusa receita de sistema sem split, que não tem âncora" do
      expect {
        described_class.from_donation_split(
          institution_id: "ins_1", donation_split_id: nil,
          account_id: account_id, amount: "10", posted_on: Date.new(2026, 4, 1)
        )
      }.to raise_error(InvalidLedgerEntry, /require a donation_split_id/)
    end
  end

  describe "immutability of the system entry" do
    # A fábrica não aceita status nem void_reason de propósito: uma entrada de
    # sistema nasce postada e nunca é anulada, e o ponto é que não exista botão
    # para outra coisa. O que dá para provar é o formato e a ausência de mutação.
    it "a fábrica não aceita status, porque não existe outro estado possível" do
      expect(described_class.method(:from_donation_split).parameters.map(&:last))
        .not_to include(:status, :void_reason)
    end

    it "nasce postada, sem caminho de volta" do
      system = described_class.from_donation_split(
        institution_id: "ins_1", donation_split_id: split_id,
        account_id: account_id, amount: "92.13", posted_on: Date.new(2026, 4, 1)
      )

      expect(system).to be_posted
      expect { system.post! }.to raise_error(InvalidLedgerEntry, /from posted to posted/)
      expect { system.void!(reason: "divergência") }
        .to raise_error(InvalidLedgerEntry, /cannot be voided/)
    end

    it "não é editável pela instituição" do
      system = described_class.from_donation_split(
        institution_id: "ins_1", donation_split_id: split_id,
        account_id: account_id, amount: "92.13", posted_on: Date.new(2026, 4, 1)
      )

      expect(system).not_to be_editable
    end
  end

  describe "posting and voiding a declared entry" do
    it "rascunho vira postado" do
      expect(entry.post!(on: Date.new(2026, 5, 1))).to be_posted
    end

    # Razão contábil não se corrige por UPDATE: a correção é um lançamento novo
    # que anula o anterior, e o anterior fica no histórico.
    it "estorna em vez de apagar, e exige justificativa" do
      posted = entry.post!
      voided = posted.void!(reason: "material devolvido")

      expect(voided).to be_voided
      expect(voided.void_reason).to eq("material devolvido")
      expect(voided.id).to eq(posted.id)
    end

    it "recusa estorno sem justificativa, antes de mudar o estado" do
      posted = entry.post!

      expect { posted.void!(reason: "  ") }
        .to raise_error(InvalidLedgerEntry, /void_reason is required when voided/)
      # O lançamento continua postado: mutar e só depois descobrir o problema
      # deixaria um lançamento estornado sem motivo, que é o estado proibido.
      expect(posted).to be_posted
      expect(posted.void_reason).to be_nil
    end

    it "não volta de estornada" do
      voided = entry.post!.void!(reason: "erro de digitação")

      expect { voided.post! }
        .to raise_error(InvalidLedgerEntry, /from voided to posted/)
    end

    it "não publica duas vezes" do
      posted = entry.post!

      expect { posted.post! }.to raise_error(InvalidLedgerEntry, /from posted to posted/)
    end
  end

  describe "invariants" do
    it "requires an institution, because the ledger belongs to the tenant" do
      expect { entry(institution_id: nil) }
        .to raise_error(InvalidLedgerEntry, /institution is required/)
    end

    it "refuses a negative amount" do
      expect { entry(amount: "-1") }.to raise_error(InvalidLedgerEntry, /cannot be negative/)
    end

    it "refuses a kind outside the closed set" do
      expect { entry(kind: :equity) }
        .to raise_error(InvalidLedgerEntry, /kind must be one of income, expense/)
    end

    it "normalizes a blank description to nil" do
      expect(entry(description: "   ").description).to be_nil
    end

    it "trims a description that exists" do
      expect(entry(description: "  tinta  ").description).to eq("tinta")
    end
  end
end
