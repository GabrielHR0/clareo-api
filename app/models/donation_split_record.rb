class DonationSplitRecord < ApplicationRecord
  self.table_name = "donation_splits"

  belongs_to :donation_record, foreign_key: :donation_id, inverse_of: :donation_split_records
  belongs_to :institution_record, foreign_key: :institution_id, optional: true

  RECIPIENTS = %w[institution platform].freeze
  STATUSES = %w[pending done cancelled blocked].freeze

  validates :recipient, inclusion: { in: RECIPIENTS }
  validates :status, inclusion: { in: STATUSES }
  validates :percentage, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  validate :institution_only_on_institution_recipient

  scope :routable, -> { where(recipient: "institution") }

  private

  def institution_only_on_institution_recipient
    if recipient == "institution" && institution_id.nil?
      errors.add(:institution_id, "é obrigatório para recipient institution")
    end

    if recipient == "platform" && institution_id.present?
      errors.add(:institution_id, "não pode existir para recipient platform")
    end
  end
end
