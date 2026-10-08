# AR record do usuário. Persistência apenas: nenhuma regra de negócio aqui.
#
# Sufixo Record para não colidir com o domínio. `UserRecord` e o agregado
# `Institution` são coisas diferentes e não podem compartilhar constante.
class UserRecord < ApplicationRecord
  self.table_name = "users"

  has_secure_password

  has_many :institution_records,
    class_name: "InstitutionRecord",
    foreign_key: :user_id,
    inverse_of: :user_record,
    dependent: :destroy

  has_many :subscription_records,
    class_name: "SubscriptionRecord",
    foreign_key: :user_id,
    inverse_of: :user_record,
    dependent: :destroy

  ROLES = %w[donor institution_admin platform_admin].freeze

  validates :email, presence: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 12 }, allow_nil: true

  def platform_admin?
    role == "platform_admin"
  end

  def institution_admin?
    role == "institution_admin"
  end

  def owns?(institution_record)
    institution_record.user_id == id
  end

  def self.authenticate(email:, password:)
    record = find_by(email: email.to_s.strip.downcase)
    return nil if record.nil?
    return nil unless record.authenticate(password.to_s)

    record
  end
end
