require_relative "../../domain_helper"

RSpec.describe Document do
  def document(**overrides)
    described_class.build(
      institution_id: "ins_1",
      target: DocumentTarget.for_ledger_entry(77),
      kind: :nota_fiscal,
      **overrides
    )
  end

  it "is private by default" do
    expect(document).not_to be_public
  end

  it "can be made public explicitly, because receipts may carry personal data" do
    expect(document(public: true)).to be_public
  end

  it "keeps the existing target coherence" do
    expect(document).to be_for_ledger_entry

    expect {
      described_class.build(
        institution_id: "ins_1",
        target: DocumentTarget.build(
          ledger_entry_id: 1,
          post_id: 2
        ),
        kind: :recibo
      )
    }.to raise_error(InvalidDocument, /cannot attach to both/)
  end
end
