class SubscriptionRecord < ApplicationRecord
  self.table_name = "subscriptions"

  belongs_to :user_record, foreign_key: :user_id, inverse_of: :subscription_records
  belongs_to :plan_record, foreign_key: :plan_id, inverse_of: :subscription_records

  STATUSES = %w[active past_due cancelled expired].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def in_good_standing?
    status == "active"
  end

  # Espelha Subscription#allows_another_institution?.
  def allows_another_institution?(current_count)
    in_good_standing? && plan_record.allows?(current_count)
  end
end
