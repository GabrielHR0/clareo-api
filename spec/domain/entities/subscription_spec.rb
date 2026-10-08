require_relative "../../domain_helper"

RSpec.describe Subscription do
  let(:pro) { Plan.build(code: :pro, name: "Pro", price: "97.00", max_institutions: 5) }
  let(:free) { Plan.build(code: :free, name: "Básico", price: "0", max_institutions: 1) }

  def subscription(**overrides)
    described_class.new(id: "sub_1", user_id: "user_1", plan: pro, **overrides)
  end

  it "carries a single subscription per user" do
    expect(subscription.user_id).to eq("user_1")
  end

  describe "institution quota" do
    it "permits another institution while below the plan limit" do
      expect(subscription.allows_another_institution?(4)).to be(true)
    end

    it "refuses another institution once the limit is reached" do
      expect(subscription.allows_another_institution?(5)).to be(false)
    end

    it "reports remaining slots" do
      expect(subscription.remaining_institution_slots(2)).to eq(3)
    end

    it "is unlimited when the plan allows it" do
      unlimited = subscription(plan: Plan.build(code: :enterprise, name: "Enterprise", price: "497.00"))

      expect(unlimited.allows_another_institution?(99)).to be(true)
      expect(unlimited.remaining_institution_slots(99)).to be_nil
    end

    it "caps a free user at one institution" do
      expect(subscription(plan: free).allows_another_institution?(1)).to be(false)
    end
  end

  describe "good standing" do
    it "holds for an active subscription" do
      expect(subscription).to be_in_good_standing
    end

    it "fails once past due, so no new institutions are registered" do
      expect(subscription.mark_past_due!).not_to be_in_good_standing
    end

    it "fails once cancelled" do
      expect(subscription.cancel!).not_to be_in_good_standing
    end

    it "withdraws the institution quota when past due" do
      expect(subscription.mark_past_due!.allows_another_institution?(0)).to be(false)
    end
  end

  it "releases the provider subscription id on cancellation" do
    record = subscription(provider_subscription_id: "sub_as_1")
    record.cancel_provider_subscription!

    expect(record.provider_subscription_id).to be_nil
  end

  it "requires a plan" do
    expect { described_class.new(id: "sub_1", user_id: "user_1", plan: nil) }
      .to raise_error(InvalidSubscription)
  end

  describe "transition guards" do
    it "refuses to fall behind once cancelled" do
      cancelled = subscription.cancel!

      expect { cancelled.mark_past_due! }
        .to raise_error(InvalidSubscription, /from cancelled to past_due/)
    end

    it "refuses to fall behind once expired" do
      expired = subscription(status: :expired)

      expect { expired.mark_past_due! }
        .to raise_error(InvalidSubscription, /from expired to past_due/)
    end

    it "refuses to cancel twice" do
      cancelled = subscription.cancel!

      expect { cancelled.cancel! }
        .to raise_error(InvalidSubscription, /from cancelled to cancelled/)
    end

    it "refuses to cancel an expired subscription" do
      expired = subscription(status: :expired)

      expect { expired.cancel! }
        .to raise_error(InvalidSubscription, /from expired to cancelled/)
    end

    it "cancels from past due, because the bill was already outstanding" do
      delinquent = subscription.mark_past_due!

      expect(delinquent.cancel!.status).to eq(:cancelled)
    end
  end
end
