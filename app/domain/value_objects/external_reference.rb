class ExternalReference
  MAX_LENGTH = 50

  attr_reader :value

  class << self
    def build(value)
      return value if value.is_a?(ExternalReference)

      new(value)
    end
  end

  def initialize(value)
    @value = value.to_s.strip
    validate!
  end

  def ==(other)
    other.is_a?(ExternalReference) && value == other.value
  end
  alias eql? ==

  def to_s
    value
  end

  private

  def validate!
    raise InvalidDonation, "external reference cannot be blank" if value.empty?
    if value.length > MAX_LENGTH
      raise InvalidDonation, "external reference cannot exceed #{MAX_LENGTH} characters"
    end
    if value.match?(/\s/)
      raise InvalidDonation, "external reference cannot contain whitespace"
    end
  end
end
