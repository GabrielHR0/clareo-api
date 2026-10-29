class PayoutRecord < ApplicationRecord
  self.table_name = "payouts"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :payout_records
  belongs_to :donation_record, foreign_key: :donation_id, optional: true, inverse_of: :payout_records

  STATUSES = %w[pending processing completed failed cancelled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :amount_brl, numericality: { greater_than: 0 }
  validates :pix_key, presence: true
  validates :provider_transfer_id, uniqueness: true, allow_nil: true
  validate :donation_belongs_to_institution

  scope :unfinished, -> { where(status: %w[pending processing]) }
  scope :completed, -> { where(status: "completed") }

  private

  def donation_belongs_to_institution
    return if donation_record.nil?

    if donation_record.institution_id != institution_id
      errors.add(:donation_id, "must belong to the same institution")
    end
  end
end
