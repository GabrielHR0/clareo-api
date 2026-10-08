# The provider only creates subaccounts for legal entities with a CNPJ.
# Individual accounts cannot have subaccounts, which is why institutions
# without a CNPJ settle through the pix_payout strategy instead.
class AccountManager
  # @param income_value [Money] mandatory on the provider side
  # @return [SubaccountSnapshot] carries the API key, returned only here
  def create_subaccount(legal_name:, cnpj:, email:, mobile_phone:, income_value:,
                        street:, street_number:, neighborhood:, postal_code:,
                        complement: nil, city: nil, legal_entity_kind: nil,
                        tax_regime: nil)
    raise NotImplementedError
  end

  # @return [SubaccountSnapshot, nil]
  def find_subaccount(provider_account_id)
    raise NotImplementedError
  end

  # @param cnpj [CpfCnpj]
  # @return [SubaccountSnapshot, nil]
  def find_subaccount_by_cnpj(cnpj)
    raise NotImplementedError
  end

  # Walks the provider's pagination envelope to find the calling account's
  # own wallet. The response is a list, not a single object.
  #
  # @return [String]
  def own_wallet_id
    raise NotImplementedError
  end
end
