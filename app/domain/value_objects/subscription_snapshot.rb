class SubscriptionSnapshot
  STATUSES = %i[active past_due cancelled expired].freeze

  attr_reader :provider_subscription_id, :status, :price, :next_charge_on

  def initialize(provider_subscription_id:, status:, price:, next_charge_on: nil)
    @provider_subscription_id = provider_subscription_id
    @status = status
    @price = Money.build(price)
    @next_charge_on = next_charge_on

    validate!
  end

  def active?
    status == :active
  end

  def ==(other)
    other.is_a?(SubscriptionSnapshot) && provider_subscription_id == other.provider_subscription_id
  end
  alias eql? ==

  private

  def validate!
    if provider_subscription_id.to_s.strip.empty?
      raise InvalidSubscription, "provider subscription id is required"
    end
    raise InvalidSubscription, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end
end
