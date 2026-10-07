class Institution
  SETTLEMENT_STRATEGIES = %i[subaccount pix_payout].freeze
  LEGAL_ENTITY_KINDS = %i[mei ltda mei_eire association].freeze
  STATUSES = %i[draft pending_approval active blocked].freeze
  REGISTRATION_STATUSES = %i[unregistered pending approved rejected].freeze

  attr_reader :id, :legal_name, :trade_name, :cnpj, :legal_entity_kind,
              :declared_monthly_revenue, :contact_email, :mobile_phone,
              :address, :pix_key, :settlement_strategy, :asaas_account_id,
              :asaas_wallet_id, :registration_status, :status

  def initialize(legal_name:, settlement_strategy:, id: nil, cnpj: nil,
                 legal_entity_kind: nil, declared_monthly_revenue: nil,
                 contact_email: nil, mobile_phone: nil, address: nil,
                 pix_key: nil, trade_name: nil, asaas_account_id: nil,
                 asaas_wallet_id: nil, registration_status: :unregistered,
                 status: :draft)
    @id = id
    @legal_name = legal_name
    @trade_name = trade_name
    @cnpj = wrap_cpf_cnpj(cnpj)
    @legal_entity_kind = legal_entity_kind
    @declared_monthly_revenue = wrap_money(declared_monthly_revenue)
    @contact_email = contact_email
    @mobile_phone = mobile_phone
    @address = address
    @pix_key = wrap_pix_key(pix_key)
    @settlement_strategy = settlement_strategy
    @asaas_account_id = asaas_account_id
    @asaas_wallet_id = asaas_wallet_id
    @registration_status = registration_status
    @status = status

    validate!
  end

  def subaccount?
    settlement_strategy == :subaccount
  end

  def pix_payout?
    settlement_strategy == :pix_payout
  end

  # Only a bound and approved subaccount can receive a split. On the pix_payout
  # path the platform holds the funds and pays out, so no provider binding is
  # needed to accept a donation.
  def accepts_donations?
    return false unless active?

    subaccount? ? provider_bound? && registration_approved? : true
  end

  def withdraws_on_its_own?
    subaccount?
  end

  def provider_bound?
    !asaas_account_id.nil? && !asaas_wallet_id.nil?
  end

  def registration_approved?
    registration_status == :approved
  end

  def active?
    status == :active
  end

  def draft?
    status == :draft
  end

  def pending_approval?
    status == :pending_approval
  end

  def blocked?
    status == :blocked
  end

  def bind_provider!(account_id:, wallet_id:)
    @asaas_account_id = account_id
    @asaas_wallet_id = wallet_id
    self
  end

  def submit_for_approval!
    transition_to!(%i[draft blocked], :pending_approval)
    self
  end

  def approve_registration!
    @registration_status = :approved
    transition_to!(%i[pending_approval blocked], :active)
    self
  end

  def reject_registration!
    @registration_status = :rejected
    transition_to!(%i[pending_approval], :blocked)
    self
  end

  def block!
    transition_to!(STATUSES, :blocked)
    self
  end

  def ==(other)
    other.is_a?(Institution) && id == other.id
  end
  alias eql? ==

  private

  def validate!
    validate_strategy!
    validate_status!
    validate_registration_status!
    validate_subaccount_requirements!
    validate_pix_payout_requirements!
  end

  def validate_strategy!
    return if SETTLEMENT_STRATEGIES.include?(settlement_strategy)

    raise InvalidInstitution, "settlement strategy must be one of #{SETTLEMENT_STRATEGIES.join(', ')}"
  end

  def validate_status!
    raise InvalidInstitution, "status must be one of #{STATUSES.join(', ')}" unless STATUSES.include?(status)
  end

  def validate_registration_status!
    return if REGISTRATION_STATUSES.include?(registration_status)

    raise InvalidInstitution, "registration status must be one of #{REGISTRATION_STATUSES.join(', ')}"
  end

  # The provider only accepts legal entities with a declared monthly revenue and
  # a complete address. Those are business facts, so they are required at the
  # domain level rather than discovered as a 400 later.
  def validate_subaccount_requirements!
    return unless subaccount?

    require_field!(cnpj, "cnpj")
    require_field!(legal_entity_kind, "legal entity kind")
    require_field!(declared_monthly_revenue, "declared monthly revenue")
    require_field!(contact_email, "contact email")
    require_field!(mobile_phone, "mobile phone")
    require_field!(address, "address")

    return if LEGAL_ENTITY_KINDS.include?(legal_entity_kind)

    raise InvalidInstitution, "legal entity kind must be one of #{LEGAL_ENTITY_KINDS.join(', ')}"
  end

  def validate_pix_payout_requirements!
    return unless pix_payout?

    require_field!(pix_key, "pix key")
  end

  def require_field!(value, field)
    raise InvalidInstitution, "#{field} is required" if value.nil?
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidInstitution, "cannot move institution from #{status} to #{target}"
    end

    @status = target
  end

  def wrap_cpf_cnpj(value)
    value.nil? ? nil : CpfCnpj.build(value)
  end

  def wrap_money(value)
    value.nil? ? nil : Money.build(value)
  end

  def wrap_pix_key(value)
    value.nil? ? nil : PixKey.build(value)
  end
end
