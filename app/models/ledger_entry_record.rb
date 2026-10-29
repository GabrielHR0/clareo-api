class LedgerEntryRecord < ApplicationRecord
  self.table_name = "ledger_entries"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :ledger_entry_records
  belongs_to :account_record, foreign_key: :account_id, inverse_of: :ledger_entry_records
  belongs_to :campaign_record, foreign_key: :campaign_id, inverse_of: :ledger_entries, optional: true
  belongs_to :donation_split_record,
    foreign_key: :donation_split_id,
    inverse_of: :ledger_entry_records,
    optional: true

  KINDS = %w[income expense].freeze
  ORIGINS = %w[donation declared].freeze
  STATUSES = %w[draft posted voided].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :origin, inclusion: { in: ORIGINS }
  validates :status, inclusion: { in: STATUSES }
  validates :amount_brl, numericality: { greater_than_or_equal_to: 0 }

  validate :void_reason_present_when_voided
  validate :donation_entries_are_immutable

  scope :posted, -> { where(status: "posted") }
  scope :income, -> { where(kind: "income") }
  scope :expense, -> { where(kind: "expense") }
  scope :declared, -> { where(origin: "declared") }
  scope :from_donations, -> { where(origin: "donation") }
  scope :in_period, ->(from, to) { where(posted_on: from..to) }
  scope :for_campaign, ->(campaign_id) { where(campaign_id: campaign_id) }

  has_many :document_records,
    foreign_key: :ledger_entry_id,
    inverse_of: :ledger_entry_record,
    dependent: :restrict_with_error

  has_many :accountability_report_entry_records,
    class_name: "AccountabilityReportEntryRecord",
    foreign_key: :ledger_entry_id,
    inverse_of: :ledger_entry_record,
    dependent: :restrict_with_error

  def system?
    origin == "donation"
  end

  # if/else em vez de guard clause: `return` dentro de bloco passado a validate
  # levanta LocalJumpError, porque o bloco não é corpo de método.
  private

  def void_reason_present_when_voided
    if status == "voided" && void_reason.blank?
      errors.add(:void_reason, "is required when voided")
    end
  end

  # Entrada de sistema é fato consumado: o webhook já liquidou o dinheiro.
  # Recusar a alteração aqui é a rede contra um UPDATE que virasse query
  # fora do domínio.
  def donation_entries_are_immutable
    if system? && !new_record?
      if status_changed? && status != "posted"
        errors.add(:status, "cannot leave posted on a donation entry")
      end

      if will_save_change_to_amount_brl? || will_save_change_to_donation_split_id? ||
         will_save_change_to_campaign_id?
        errors.add(:base, "a donation entry cannot be rewritten")
      end
    end
  end
end
