class CpfCnpj
  CPF_LENGTH = 11
  CNPJ_LENGTH = 14

  CPF_FIRST_WEIGHTS = [ 10, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze
  CPF_SECOND_WEIGHTS = [ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze
  CNPJ_FIRST_WEIGHTS = [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze
  CNPJ_SECOND_WEIGHTS = [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze

  attr_reader :digits

  class << self
    def build(value)
      return value if value.is_a?(CpfCnpj)

      new(value)
    end
  end

  def initialize(value)
    @digits = value.to_s.gsub(/\D/, "")
    validate_format!
    validate_check_digits!
  end

  def cpf?
    digits.length == CPF_LENGTH
  end

  def cnpj?
    digits.length == CNPJ_LENGTH
  end

  def ==(other)
    other.is_a?(CpfCnpj) && digits == other.digits
  end
  alias eql? ==

  def to_s
    digits
  end

  def formatted
    return "#{digits[0, 3]}.#{digits[3, 3]}.#{digits[6, 3]}-#{digits[9, 2]}" if cpf?

    "#{digits[0, 2]}.#{digits[2, 3]}.#{digits[5, 3]}/#{digits[8, 4]}-#{digits[12, 2]}"
  end

  private

  def validate_format!
    unless cpf? || cnpj?
      raise InvalidInstitution, "document must be 11 (CPF) or 14 (CNPJ) digits, got #{digits.length}"
    end
    raise InvalidInstitution, "document cannot have all digits equal" if digits.chars.uniq.length == 1
  end

  def validate_check_digits!
    valid = cpf? ? valid_cpf? : valid_cnpj?
    raise InvalidInstitution, "document check digits are invalid" unless valid
  end

  def valid_cpf?
    digits[9].to_i == check_digit(9, CPF_FIRST_WEIGHTS) &&
      digits[10].to_i == check_digit(10, CPF_SECOND_WEIGHTS)
  end

  def valid_cnpj?
    digits[12].to_i == check_digit(12, CNPJ_FIRST_WEIGHTS) &&
      digits[13].to_i == check_digit(13, CNPJ_SECOND_WEIGHTS)
  end

  def check_digit(length, weights)
    total = 0
    digits[0, length].chars.each_with_index do |char, index|
      total += char.to_i * weights[index]
    end
    remainder = total % 11
    remainder < 2 ? 0 : 11 - remainder
  end
end
