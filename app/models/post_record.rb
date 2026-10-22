class PostRecord < ApplicationRecord
  self.table_name = "posts"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :post_records

  TYPES = %w[update report].freeze
  STATUSES = %w[published hidden].freeze

  validates :title, presence: true
  validates :content, presence: true
  validates :post_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :published, -> { where(status: "published") }
  scope :hidden, -> { where(status: "hidden") }
  scope :in_feed, -> { published.order(published_at: :desc, id: :desc) }

  has_many :document_records,
    foreign_key: :post_id,
    inverse_of: :post_record,
    dependent: :restrict_with_error

  def hidden?
    status == "hidden"
  end
end
