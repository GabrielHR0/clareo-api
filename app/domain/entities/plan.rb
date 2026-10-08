class Plan
  TIERS = %i[free pro enterprise].freeze

  attr_reader :code, :name, :price, :max_institutions, :features

  class << self
    def build(code:, name:, price:, max_institutions: nil, features: [])
      new(
        code: code,
        name: name,
        price: price,
        max_institutions: max_institutions,
        features: features
      )
    end
  end

  def initialize(code:, name:, price:, max_institutions: nil, features: [])
    @code = code
    @name = name
    @price = Money.build(price)
    @max_institutions = max_institutions
    @features = features

    validate!
  end

  def free?
    price.zero?
  end

  def unlimited_institutions?
    max_institutions.nil?
  end

  def allows?(institution_count)
    unlimited_institutions? || institution_count < max_institutions
  end

  def remaining_slots(institution_count)
    return nil if unlimited_institutions?

    [ max_institutions - institution_count, 0 ].max
  end

  def ==(other)
    other.is_a?(Plan) && code == other.code
  end
  alias eql? ==

  private

  def validate!
    unless TIERS.include?(code)
      raise InvalidSubscription, "plan code must be one of #{TIERS.join(', ')}"
    end
    raise InvalidSubscription, "plan name cannot be blank" if name.to_s.strip.empty?
    raise InvalidSubscription, "plan price cannot be negative" if price.negative?
    return if max_institutions.nil? || max_institutions.positive?

    raise InvalidSubscription, "max institutions must be positive"
  end
end
