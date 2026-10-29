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

  def income?
    kind == "income"
  end

  def expense?
    kind == "expense"
  end
end
