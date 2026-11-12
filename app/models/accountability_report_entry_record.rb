# Linha congelada do relatório. As colunas de conta e campanha são snapshot,
# não cache: elas preservam como a prestação foi publicada mesmo que o cadastro
# mude depois.
class AccountabilityReportEntryRecord < ApplicationRecord
  self.table_name = "accountability_report_entries"

  belongs_to :accountability_report_record,
    foreign_key: :accountability_report_id,
    inverse_of: :entry_records

  belongs_to :institution_record,
    foreign_key: :institution_id,
    inverse_of: :accountability_report_entry_records

  belongs_to :ledger_entry_record,
    foreign_key: :ledger_entry_id,
    inverse_of: :accountability_report_entry_records

  belongs_to :account_record,
    foreign_key: :account_id,
    inverse_of: :accountability_report_entry_records

  belongs_to :campaign_record,
    foreign_key: :campaign_id,
    optional: true

  KINDS = %w[income expense].freeze
  ORIGINS = %w[donation declared].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :origin, inclusion: { in: ORIGINS }
  validates :account_code, :account_name, :posted_on, presence: true
  validates :amount_brl, numericality: { greater_than_or_equal_to: 0 }
  validate :references_belong_to_institution

  def income?
    kind == "income"
  end

  def expense?
    kind == "expense"
  end

  private

  def references_belong_to_institution
    if accountability_report_record &&
       accountability_report_record.institution_id != institution_id
      errors.add(:accountability_report_id, "must belong to the same institution")
    end

    if ledger_entry_record && ledger_entry_record.institution_id != institution_id
      errors.add(:ledger_entry_id, "must belong to the same institution")
    end

    if account_record && account_record.institution_id != institution_id
      errors.add(:account_id, "must belong to the same institution")
    end

    if campaign_record && campaign_record.institution_id != institution_id
      errors.add(:campaign_id, "must belong to the same institution")
    end
  end
end
