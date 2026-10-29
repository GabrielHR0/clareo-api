# AR record do plano de contas. O agregado Account (app/domain/entities)
# carrega as regras; este record só persiste e valida o que o banco exige.
class AccountRecord < ApplicationRecord
  self.table_name = "accounts"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :account_records

  has_many :ledger_entry_records,
    class_name: "LedgerEntryRecord",
    foreign_key: :account_id,
    inverse_of: :account_record,
    dependent: :restrict_with_error

  has_many :accountability_report_entry_records,
    class_name: "AccountabilityReportEntryRecord",
    foreign_key: :account_id,
    inverse_of: :account_record,
    dependent: :restrict_with_error

  NATURES = %w[income expense].freeze

  validates :code, presence: true, uniqueness: { scope: :institution_id }
  validates :name, presence: true
  validates :nature, inclusion: { in: NATURES }

  validate :parent_is_not_self
  validate :system_account_stays_active
  validate :system_account_keeps_nature

  scope :active, -> { where(active: true) }
  scope :system, -> { where(system: true) }
  scope :income, -> { where(nature: "income") }
  scope :expense, -> { where(nature: "expense") }

  def income?
    nature == "income"
  end

  def expense?
    nature == "expense"
  end

  private

  # As validações de conta system usam if/else, não guard clause: `return` dentro
  # de um bloco passado a validate levanta LocalJumpError, porque o bloco não é
  # corpo de método.

  # A conta de receita de doação é system: true e não pode ser desativada,
  # porque a receita automática do split aponta para ela por código. A validação
  # do model dá mensagem utilizável; a regra continua valendo no domínio.
  def system_account_stays_active
    if system? && !active?
      errors.add(:active, "cannot deactivate a system account")
    end
  end

  def system_account_keeps_nature
    if system? && nature_changed? && nature_was.present?
      errors.add(:nature, "cannot change the nature of a system account")
    end
  end

  def parent_is_not_self
    if parent_code.present? && parent_code == code
      errors.add(:parent_code, "cannot be the account itself")
    end
  end
end
