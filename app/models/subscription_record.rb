class SubscriptionRecord < ApplicationRecord
  self.table_name = "subscriptions"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :subscription_record
  belongs_to :plan_record, foreign_key: :plan_id, inverse_of: :subscription_records

  STATUSES = %w[active past_due cancelled expired].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }

  def in_good_standing?
    status == "active"
  end
end
