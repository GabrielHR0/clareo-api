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
  validates :max_institutions, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  def unlimited_institutions?
    max_institutions.nil?
  end

  def free?
    price_brl.zero?
  end

  # Espelha Plan#allows?.
  def allows?(institution_count)
    unlimited_institutions? || institution_count < max_institutions
  end

  def remaining_slots(institution_count)
    return nil if unlimited_institutions?

    [ max_institutions - institution_count, 0 ].max
  end
end
