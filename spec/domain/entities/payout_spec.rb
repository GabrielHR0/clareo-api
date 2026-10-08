require_relative "../../domain_helper"

RSpec.describe Payout do
  let(:institution) do
    Institution.new(
      id: "ins_1",
      legal_name: "Criador de Conteudo",
      settlement_strategy: :pix_payout,
      pix_key: "financeiro@criador.com"
    )
  end

  def payout(**overrides)
    described_class.new(
      id: "pay_1",
      institution: institution,
      amount: "92.13",
      pix_key: "financeiro@criador.com",
      **overrides
    )
  end

  it "requires a positive amount" do
    expect { payout(amount: "0.00") }.to raise_error(InvalidDonation)
  end

  it "walks pending to completed" do
    record = payout

    expect { record.start_processing!(provider_transfer_id: "tra_1") }
      .to change(record, :status).from(:pending).to(:processing)

    expect { record.complete!(at: Time.now) }.to change(record, :status).to(:completed)
    expect(record.provider_transfer_id).to eq("tra_1")
  end

  it "records a failure with a reason" do
    record = payout
    record.start_processing!(provider_transfer_id: "tra_1")

    expect { record.fail!(reason: "recipient rejected") }.to change(record, :status).to(:failed)
    expect(record.failure_reason).to eq("recipient rejected")
  end

  it "refuses to complete an already failed payout" do
    record = payout
    record.start_processing!(provider_transfer_id: "tra_1")
    record.fail!

    expect { record.complete! }.to raise_error(InvalidDonation)
  end
end
