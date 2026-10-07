class PayoutRecord < ApplicationRecord
  self.table_name = "payouts"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :payout_records
  belongs_to :donation_record, foreign_key: :donation_id, optional: true, inverse_of: :payout_records

  STATUSES = %w[pending processing completed failed cancelled].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :amount_brl, numericality: { greater_than: 0 }
  validates :pix_key, presence: true
  validates :provider_transfer_id, uniqueness: true, allow_nil: true

  scope :unfinished, -> { where(status: %w[pending processing]) }
  scope :completed, -> { where(status: "completed") }
end
