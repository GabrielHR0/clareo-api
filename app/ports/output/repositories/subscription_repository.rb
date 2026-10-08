module Repositories
  # One active subscription per institution is the rule, enforced here so the
  # database cannot end up with two. A user may own several institutions, each
  # with its own subscription and its own plan.
  class SubscriptionRepository
    # @return [Subscription, nil]
    def find(id)
      raise NotImplementedError
    end

    # @return [Subscription, nil] the institution's single active subscription
    def find_active_by_institution(institution_id)
      raise NotImplementedError
    end

    def save(subscription)
      raise NotImplementedError
    end
  end
end
