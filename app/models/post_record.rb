class PostRecord < ApplicationRecord
  self.table_name = "posts"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :post_records
  belongs_to :campaign_record,
    foreign_key: :campaign_id,
    inverse_of: :post_records,
    optional: true

  TYPES = %w[update report].freeze
  STATUSES = %w[published hidden].freeze

  validates :title, presence: true
  validates :content, presence: true
  validates :post_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published") }
  scope :hidden, -> { where(status: "hidden") }
  scope :in_feed, -> { published.order(published_at: :desc, id: :desc) }
  scope :for_campaign, ->(campaign_id) { where(campaign_id: campaign_id) }

  has_many :document_records,
    foreign_key: :post_id,
    inverse_of: :post_record,
    dependent: :restrict_with_error

  validate :campaign_belongs_to_institution

  def hidden?
    status == "hidden"
  end

  private

  def campaign_belongs_to_institution
    return if campaign_id.nil?

    if campaign_record.nil? || campaign_record.institution_id != institution_id
      errors.add(:campaign_id, "must belong to the same institution")
    end
  end
end
