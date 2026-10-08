# The provider requires a registered payer before any charge exists, and it
# happily creates duplicates. Deduplication is ours, so it belongs here.
class CustomerRegistry
  # @param external_reference [ExternalReference]
  # @return [String] provider customer id
  def register(name:, email:, cpf_cnpj:, mobile_phone: nil, external_reference: nil)
    raise NotImplementedError
  end

  # @return [String, nil]
  def find_by_external_reference(external_reference)
    raise NotImplementedError
  end

  # @return [String, nil]
  def find_by_cpf_cnpj(cpf_cnpj)
    raise NotImplementedError
  end
end
