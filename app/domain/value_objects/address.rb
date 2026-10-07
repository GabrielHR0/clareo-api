class Address
  attr_reader :street, :number, :neighborhood, :postal_code, :complement, :city

  class << self
    def build(street:, number:, neighborhood:, postal_code:, complement: nil, city: nil)
      new(
        street: street,
        number: number,
        neighborhood: neighborhood,
        postal_code: postal_code,
        complement: complement,
        city: city
      )
    end
  end

  def initialize(street:, number:, neighborhood:, postal_code:, complement: nil, city: nil)
    @street = presence(street, "street")
    @number = presence(number, "number")
    @neighborhood = presence(neighborhood, "neighborhood")
    @postal_code = normalize_postal_code(presence(postal_code, "postal code"))
    @complement = normalize(complement)
    @city = normalize(city)
  end

  def ==(other)
    other.is_a?(Address) && to_h == other.to_h
  end
  alias eql? ==

  def to_h
    {
      street: street,
      number: number,
      neighborhood: neighborhood,
      postal_code: postal_code,
      complement: complement,
      city: city
    }
  end

  private

  def presence(value, field)
    normalized = normalize(value)
    raise InvalidInstitution, "#{field} cannot be blank" if normalized.nil?

    normalized
  end

  def normalize(value)
    stripped = value.to_s.strip
    stripped.empty? ? nil : stripped
  end

  def normalize_postal_code(value)
    digits = value.gsub(/\D/, "")
    raise InvalidInstitution, "postal code must have 8 digits" if digits.length != 8

    "#{digits[0, 5]}-#{digits[5, 3]}"
  end
end
