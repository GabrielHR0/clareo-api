class CampaignRecord < ApplicationRecord
  self.table_name = "campaigns"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :campaign_records

  STATUSES = %w[active paused closed].freeze

  validates :title, presence: true
  validates :description, presence: true
  validates :goal_brl, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validate :period_is_ordered

  scope :active, -> { where(status: "active") }
  scope :in_feed, -> { active.order(starts_on: :desc, id: :desc) }

  # O recurso doado para a campanha: lançamentos de sistema. É o que prova
  # quanto entrou, e é por isso que o agregado não guarda esse número.
  has_many :ledger_entries,
    class_name: "LedgerEntryRecord",
    foreign_key: :campaign_id,
    inverse_of: :campaign_record,
    dependent: :nullify

  has_many :post_records,
    class_name: "PostRecord",
    foreign_key: :campaign_id,
    inverse_of: :campaign_record,
    dependent: :nullify

  has_many :accountability_report_records,
    class_name: "AccountabilityReportRecord",
    foreign_key: :campaign_id,
    inverse_of: :campaign_record,
    dependent: :nullify

  # Deliberadamente sem current_amount e sem amount_raised: os dois são
  # derivados dos lançamentos. Cache aqui dessincroniza quando um split é
  # estornado, e a campanha passa a anunciar um valor que não existe mais.
  def raised_brl
    ledger_entries.from_donations.sum(:amount_brl)
  end

  def applied_brl
    ledger_entries.expense.declared.sum(:amount_brl)
  end

  private

  def period_is_ordered
    if starts_on.present? && ends_on.present? && ends_on < starts_on
      errors.add(:ends_on, "cannot be before starts_on")
    end
  end
end
