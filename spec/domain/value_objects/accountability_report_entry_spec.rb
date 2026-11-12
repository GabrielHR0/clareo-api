require_relative "../../domain_helper"

RSpec.describe AccountabilityReportEntry do
  let(:account) do
    Account.build(
      id: 11,
      institution_id: "ins_1",
      code: "1.1",
      name: "Receitas de Doações",
      nature: :income,
      system: true
    )
  end

  let(:ledger_entry) do
    LedgerEntry.from_donation_split(
      id: 77,
      institution_id: "ins_1",
      donation_split_id: 5,
      account_id: 11,
      amount: "92.13",
      posted_on: Date.new(2026, 1, 15),
      campaign_id: 3,
      description: "Doação da campanha"
    )
  end

  def entry(**overrides)
    described_class.build(
      institution_id: "ins_1",
      ledger_entry_id: 77,
      account_id: 11,
      account_code: "1.1",
      account_name: "Receitas de Doações",
      kind: :income,
      origin: :donation,
      posted_on: Date.new(2026, 1, 15),
      amount: "92.13",
      **overrides
    )
  end

  it "snapshots the ledger entry and account at the time of reporting" do
    snapshot = described_class.from_ledger_entry(entry: ledger_entry, account: account)

    expect(snapshot.ledger_entry_id).to eq(77)
    expect(snapshot.account_id).to eq(11)
    expect(snapshot.account_code).to eq("1.1")
    expect(snapshot.account_name).to eq("Receitas de Doações")
    expect(snapshot.campaign_id).to eq(3)
    expect(snapshot.amount).to eq(Money.brl("92.13"))
    expect(snapshot).to be_income
    expect(snapshot).to be_system
  end

  it "requires the account code and name, because the report groups by category" do
    expect { entry(account_code: "") }
      .to raise_error(InvalidAccountabilityReport, /account code/)

    expect { entry(account_name: " ") }
      .to raise_error(InvalidAccountabilityReport, /account name/)
  end

  it "requires a cash date, otherwise the entry cannot belong to a period" do
    expect { entry(posted_on: nil) }
      .to raise_error(InvalidAccountabilityReport, /posted_on/)
  end

  it "refuses a negative amount" do
    expect { entry(amount: "-1.00") }
      .to raise_error(InvalidAccountabilityReport, /negative/)
  end

  it "refuses unknown kind or origin" do
    expect { entry(kind: :transfer) }
      .to raise_error(InvalidAccountabilityReport, /kind/)

    expect { entry(origin: :guess) }
      .to raise_error(InvalidAccountabilityReport, /origin/)
  end

  it "is identified by the ledger entry inside the tenant" do
    expect(entry).to eq(entry(amount: "1.00"))
    expect(entry).not_to eq(entry(ledger_entry_id: 78))
  end
end
