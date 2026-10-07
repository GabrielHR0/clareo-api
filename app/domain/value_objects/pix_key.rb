class PixKey
  EVP_LENGTH = 36

  attr_reader :value, :type

  class << self
    def build(value)
      return value if value.is_a?(PixKey)

      new(value)
    end
  end

  def initialize(value)
    @value = value.to_s.gsub(/\s+/, "")
    validate_presence!
    @type = detect_type
  end

  def random?
    type == :random
  end

  def cnpj?
    type == :cnpj
  end

  def cpf?
    type == :cpf
  end

  def ==(other)
    other.is_a?(PixKey) && value == other.value
  end
  alias eql? ==

  def to_s
    value
  end

  private

  def validate_presence!
    raise InvalidInstitution, "pix key cannot be blank" if value.empty?
  end

  # Format is deliberately not validated beyond presence: the Banco Central
  # rules are complex and change over time, and a local validator that is
  # subtly wrong rejects valid keys. The provider is the authority.
  def detect_type
    return :email if value.include?("@")
    return :cpf if valid_cpf_key?
    return :cnpj if valid_cnpj_key?
    return :random if evp?

    :phone
  end

  def valid_cpf_key?
    return false unless value.match?(/\A\d{11}\z/)

    CpfCnpj.new(value).cpf?
  rescue InvalidInstitution
    false
  end

  def valid_cnpj_key?
    return false unless value.match?(/\A\d{14}\z/)

    CpfCnpj.new(value).cnpj?
  rescue InvalidInstitution
    false
  end

  def evp?
    value.match?(/\A[A-Za-z0-9]{8}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{4}-[A-Za-z0-9]{12}\z/)
  end
end
