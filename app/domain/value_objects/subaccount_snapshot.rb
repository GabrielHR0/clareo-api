class SubaccountSnapshot
  REGISTRATION_STATUSES = %i[unregistered pending approved rejected].freeze

  attr_reader :provider_account_id, :wallet_id, :api_key, :city, :state,
              :registration_status, :commercial_info_expired,
              :commercial_info_expires_on

  class << self
    # Only the creation response carries the API key, and only once.
    def created(provider_account_id:, wallet_id:, api_key:, city: nil, state: nil,
                registration_status: :pending,
                commercial_info_expired: false, commercial_info_expires_on: nil)
      new(
        provider_account_id: provider_account_id,
        wallet_id: wallet_id,
        api_key: api_key,
        city: city,
        state: state,
        registration_status: registration_status,
        commercial_info_expired: commercial_info_expired,
        commercial_info_expires_on: commercial_info_expires_on
      )
    end
  end

  def initialize(provider_account_id:, wallet_id:, api_key: nil, city: nil, state: nil,
                 registration_status: :unregistered, commercial_info_expired: false,
                 commercial_info_expires_on: nil)
    @provider_account_id = provider_account_id
    @wallet_id = wallet_id
    @api_key = api_key
    @city = city
    @state = state
    @registration_status = registration_status
    @commercial_info_expired = commercial_info_expired
    @commercial_info_expires_on = commercial_info_expires_on

    validate!
  end

  def approved?
    registration_status == :approved
  end

  def commercial_info_expiring?
    commercial_info_expired || !commercial_info_expires_on.nil?
  end

  private

  def validate!
    raise InvalidInstitution, "subaccount id is required" if provider_account_id.to_s.strip.empty?
    raise InvalidInstitution, "wallet id is required" if wallet_id.to_s.strip.empty?
    return if REGISTRATION_STATUSES.include?(registration_status)

    raise InvalidInstitution, "registration status must be one of #{REGISTRATION_STATUSES.join(', ')}"
  end
end
