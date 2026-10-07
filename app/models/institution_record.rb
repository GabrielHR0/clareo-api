# AR record da instituição. O agregado Institution (app/domain/entities)
# carrega as regras; este record só persiste e valida o que o banco exige.
class InstitutionRecord < ApplicationRecord
  self.table_name = "institutions"

  belongs_to :user_record, foreign_key: :user_id, inverse_of: :institution_records

  has_many :donation_records,
    class_name: "DonationRecord",
    foreign_key: :institution_id,
    inverse_of: :institution_record,
    dependent: :restrict_with_error

  has_many :payout_records,
    class_name: "PayoutRecord",
    foreign_key: :institution_id,
    inverse_of: :institution_record,
    dependent: :restrict_with_error

  SETTLEMENT_STRATEGIES = %w[subaccount pix_payout].freeze
  STATUSES = %w[draft pending_approval active blocked].freeze
  REGISTRATION_STATUSES = %w[unregistered pending approved rejected].freeze
  LEGAL_ENTITY_KINDS = %w[mei ltda mei_eire association].freeze

  validates :legal_name, presence: true
  validates :settlement_strategy, inclusion: { in: SETTLEMENT_STRATEGIES }
  validates :status, inclusion: { in: STATUSES }
  validates :registration_status, inclusion: { in: REGISTRATION_STATUSES }
  validates :legal_entity_kind, inclusion: { in: LEGAL_ENTITY_KINDS }, allow_nil: true
  validates :cnpj, uniqueness: true, allow_nil: true

  validates :declared_monthly_revenue,
    numericality: { greater_than_or_equal_to: 0 },
    allow_nil: true

  def subaccount?
    settlement_strategy == "subaccount"
  end

  def pix_payout?
    settlement_strategy == "pix_payout"
  end

  def active?
    status == "active"
  end

  def provider_bound?
    asaas_account_id.present? && asaas_wallet_id.present?
  end

  def registration_approved?
    registration_status == "approved"
  end

  # Espelha Institution#accepts_donations? para que a listagem de instituições
  # não precise carregar e instanciar o agregado só para filtrar.
  def accepts_donations?
    return false unless active?

    subaccount? ? provider_bound? && registration_approved? : true
  end

  def address
    return nil if address_street.blank?

    Address.build(
      street: address_street,
      number: address_number,
      neighborhood: address_neighborhood,
      postal_code: address_postal_code,
      complement: address_complement,
      city: address_city
    )
  end
end
