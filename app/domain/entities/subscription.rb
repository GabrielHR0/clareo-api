class Subscription
  STATUSES = %i[active past_due cancelled expired].freeze

  attr_reader :id, :user_id, :plan, :provider_subscription_id, :status,
              :current_period_ends_at, :cancelled_at

  def initialize(user_id:, plan:, id: nil, provider_subscription_id: nil,
                 status: :active, current_period_ends_at: nil, cancelled_at: nil)
    @id = id
    @user_id = user_id
    @plan = plan
    @provider_subscription_id = provider_subscription_id
    @status = status
    @current_period_ends_at = current_period_ends_at
    @cancelled_at = cancelled_at

    validate!
  end

  # A delinquent or cancelled subscription does not entitle the user to register
  # new institutions. Existing institutions keep running.
  def in_good_standing?
    status == :active
  end

  def allows_another_institution?(institution_count)
    in_good_standing? && plan.allows?(institution_count)
  end

  def remaining_institution_slots(institution_count)
    return nil unless in_good_standing?

    plan.remaining_slots(institution_count)
  end

  # Cancelling is only meaningful while the provider can still charge. Once
  # cancelled or expired there is nothing left to cancel, and a late webhook
  # replaying the event must not reopen the subscription.
  def cancel!(at: nil)
    transition_to!(%i[active past_due], :cancelled)
    @cancelled_at = at
    self
  end

  # Only an active subscription can fall behind. A cancelled or expired one
  # cannot become delinquent: that would grant standing back to a subscription
  # the provider already closed.
  def mark_past_due!
    transition_to!(%i[active], :past_due)
    self
  end

  def cancel_provider_subscription!
    @provider_subscription_id = nil
    self
  end

  def ==(other)
    other.is_a?(Subscription) && id == other.id
  end
  alias eql? ==

  private

  def validate!
    raise InvalidSubscription, "user is required" if user_id.nil?
    raise InvalidSubscription, "plan is required" if plan.nil?
    raise InvalidSubscription, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidSubscription, "cannot move subscription from #{status} to #{target}"
    end

    @status = target
  end
end
