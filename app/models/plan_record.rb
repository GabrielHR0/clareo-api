class PlanRecord < ApplicationRecord
  self.table_name = "plans"

  has_many :subscription_records,
    class_name: "SubscriptionRecord",
    foreign_key: :plan_id,
    inverse_of: :plan_record,
    dependent: :restrict_with_error

  TIERS = %w[free pro enterprise].freeze

  validates :code, presence: true, inclusion: { in: TIERS }, uniqueness: true
  validates :name, presence: true
  validates :price_brl, numericality: { greater_than_or_equal_to: 0 }

  def free?
    price_brl.zero?
  end
end
