class SubscriptionManager
  # @return [SubscriptionSnapshot]
  def subscribe(customer_id:, price:, reference:, due_on:, cycle: :monthly,
                split: nil)
    raise NotImplementedError
  end

  # @return [SubscriptionSnapshot, nil]
  def find_subscription(provider_subscription_id)
    raise NotImplementedError
  end

  # @return [SubscriptionSnapshot]
  def cancel_subscription(provider_subscription_id)
    raise NotImplementedError
  end
end
