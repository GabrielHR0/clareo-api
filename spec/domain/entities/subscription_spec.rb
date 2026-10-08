require_relative "../../domain_helper"

# A assinatura pertence à instituição. Um usuário pode ter várias, cada uma
# pagando o seu próprio plano.
RSpec.describe Subscription do
  let(:pro) { Plan.build(code: :pro, name: "Pro", price: "97.00") }
  let(:free) { Plan.build(code: :free, name: "Básico", price: "0") }

  def subscription(**overrides)
    described_class.new(id: "sub_1", institution_id: "ins_1", plan: pro, **overrides)
  end

  it "belongs to an institution, not to a user" do
    expect(subscription.institution_id).to eq("ins_1")
    expect(described_class.instance_methods).not_to include(:user_id)
  end

  describe "good standing" do
    it "holds for an active subscription" do
      expect(subscription).to be_in_good_standing
    end

    it "fails once past due, which stops publishing but not donations" do
      delinquent = subscription.mark_past_due!

      expect(delinquent).not_to be_in_good_standing
    end

    it "fails once cancelled" do
      expect(subscription.cancel!).not_to be_in_good_standing
    end
  end

  describe "publishing gate" do
    # Não há feature flag nem contagem a consultar: a assinatura É o plano, então
    # publicar e estar em dia são a mesma pergunta.
    it "allows publishing while active" do
      expect(subscription).to be_in_good_standing
    end

    it "blocks publishing when past due" do
      expect(subscription.mark_past_due!).not_to be_in_good_standing
    end

    it "blocks publishing when cancelled" do
      expect(subscription.cancel!).not_to be_in_good_standing
    end

    it "does not carry a separate publishing flag, because it would be the same answer" do
      expect(described_class.instance_methods).not_to include(:publishing_allowed?)
    end
  end

  it "releases the provider subscription id on cancellation" do
    record = subscription(provider_subscription_id: "sub_as_1")
    record.cancel_provider_subscription!

    expect(record.provider_subscription_id).to be_nil
  end

  it "requires an institution" do
    expect { described_class.new(id: "sub_1", institution_id: nil, plan: pro) }
      .to raise_error(InvalidSubscription, /institution is required/)
  end

  it "requires a plan" do
    expect { described_class.new(id: "sub_1", institution_id: "ins_1", plan: nil) }
      .to raise_error(InvalidSubscription, /plan is required/)
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
