module Repositories
# One active subscription per user is the rule, enforced here so the
# database cannot end up with two.
class SubscriptionRepository
  # @return [Subscription, nil]
  def find(id)
    raise NotImplementedError
  end

  # @return [Subscription, nil] the user's single active subscription
  def find_active_by_user(user_id)
    raise NotImplementedError
  end

  def save(subscription)
    raise NotImplementedError
  end
end
end
