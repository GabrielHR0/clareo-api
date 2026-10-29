# AR record da prestação de contas. O agregado AccountabilityReport concentra
# as regras; aqui só persistimos o estado e as relações do tenant.
class AccountabilityReportRecord < ApplicationRecord
  self.table_name = "accountability_reports"

  belongs_to :institution_record,
    foreign_key: :institution_id,
    inverse_of: :accountability_report_records

  belongs_to :campaign_record,
    foreign_key: :campaign_id,
    inverse_of: :accountability_report_records,
    optional: true

  belongs_to :reviewer,
    class_name: "UserRecord",
    foreign_key: :reviewer_id,
    inverse_of: :reviewed_accountability_report_records,
    optional: true

  has_many :entry_records,
    class_name: "AccountabilityReportEntryRecord",
    foreign_key: :accountability_report_id,
    inverse_of: :accountability_report_record,
    dependent: :destroy

  STATUSES = %w[draft submitted under_review approved changes_requested published].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :period_is_ordered
  validate :campaign_belongs_to_institution

  scope :published, -> { where(status: "published") }
  scope :not_draft, -> { where.not(status: "draft") }
  scope :in_review, -> { where(status: %w[submitted under_review]) }

  def published?
    status == "published"
  end

  def editable?
    %w[draft changes_requested].include?(status)
  end

  private

  def period_is_ordered
    if period_start.present? && period_end.present? && period_end < period_start
      errors.add(:period_end, "cannot be before period_start")
    end
  end

  def campaign_belongs_to_institution
    if campaign_record && campaign_record.institution_id != institution_id
      errors.add(:campaign_id, "must belong to the same institution")
    end
  end
end
