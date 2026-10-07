class DonationRecord < ApplicationRecord
  self.table_name = "donations"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :donation_records

  has_many :donation_split_records,
    class_name: "DonationSplitRecord",
    foreign_key: :donation_id,
    inverse_of: :donation_record,
    dependent: :destroy

  has_many :payout_records,
    class_name: "PayoutRecord",
    foreign_key: :donation_id,
    inverse_of: :donation_record,
    dependent: :nullify

  PAYMENT_METHODS = %w[pix boleto credit_card].freeze
  STATUSES = %w[pending received refunded cancelled rejected split_blocked].freeze

  validates :donor_name, presence: true
  validates :reference, presence: true, uniqueness: true
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount_brl, numericality: { greater_than: 0 }
  validates :net_amount_brl, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :asaas_payment_id, uniqueness: true, allow_nil: true

  scope :received, -> { where(status: "received") }
  scope :settled, -> { where(status: %w[received refunded]) }

  def received?
    status == "received"
  end

  def pending?
    status == "pending"
  end
end
