require_relative "../../domain_helper"

RSpec.describe WebhookEvent do
  def event(**overrides)
    described_class.new(
      provider_event_id: "evt_1",
      event: "PAYMENT_RECEIVED",
      payload: { "id" => "pay_1" },
      resource_type: "payment",
      resource_id: "pay_1",
      **overrides
    )
  end

it "requires the provider event id, which is the idempotency key" do
      expect { described_class.new(provider_event_id: " ", event: "PAYMENT_RECEIVED", payload: {}, resource_type: "payment", resource_id: "pay_1") }
        .to raise_error(InvalidDonation)
    end

  describe "processing lifecycle" do
    it "counts attempts" do
      record = event

      expect { record.start_processing! }.to change(record, :attempts).from(0).to(1)
      expect(record).to be_processing
    end

    it "allows a retry after a failure" do
      record = event
      record.start_processing!
      record.failed!(message: "timeout")

      expect { record.start_processing! }.to change(record, :attempts).from(1).to(2)
    end

    it "refuses to process an already processed event, so the effect is not applied twice" do
      record = event
      record.start_processing!
      record.processed!

      expect(record).to be_already_processed
      expect { record.start_processing! }.to raise_error(InvalidDonation)
    end

    it "keeps the failure message for investigation" do
      record = event
      record.start_processing!
      record.failed!(message: "provider timeout")

      expect(record.error_message).to eq("provider timeout")
    end
  end
end
