class SplitPolicy
  # Plain string on purpose: a constant built from another constant is evaluated
  # at class definition time, and eager loading does not respect load order.
  DEFAULT_MINIMUM_DONATION = "50.00"

  DEFAULT_TIER_BOUNDS = [ "50.00", "100.00", "250.00" ].freeze
  DEFAULT_TIER_PERCENTAGES = [ "10", "6", "4", "2.5" ].freeze

  attr_reader :tiers, :minimum_donation

  class << self
    def default
      new
    end
  end

  def initialize(tiers: nil, minimum_donation: nil)
    @tiers = normalize_tiers(tiers || default_tiers)
    @minimum_donation = Money.build(minimum_donation || DEFAULT_MINIMUM_DONATION)

    validate!
  end

  # Tiers exist because the provider charges a flat fee per received charge.
  # A single percentage cannot stay profitable for small donations and stay
  # competitive for large ones.
  def percentage_for(amount)
    money = Money.build(amount)
    tiers.find { |tier| tier[:upto].nil? || money <= tier[:upto] }[:percentage]
  end

  def accepts?(amount)
    Money.build(amount) >= minimum_donation
  end

  def to_h
    tiers.map do |tier|
      {
        upto: tier[:upto]&.to_s,
        percentage: tier[:percentage].to_s
      }
    end
  end

  private

  def default_tiers
    bounds = DEFAULT_TIER_BOUNDS.map { |value| Money.build(value) }
    bounds << nil

    bounds.each_with_index.map do |upto, index|
      { upto: upto, percentage: Percentage.build(DEFAULT_TIER_PERCENTAGES.fetch(index)) }
    end
  end

  def normalize_tiers(tiers)
    tiers.map do |tier|
      {
        upto: tier[:upto].nil? ? nil : Money.build(tier[:upto]),
        percentage: Percentage.build(tier[:percentage])
      }
    end
  end

  def validate!
    raise InvalidSplit, "split policy needs at least one tier" if tiers.empty?

    tiers.each do |tier|
      if tier[:percentage].zero?
        raise InvalidSplit, "tier percentage cannot be zero"
      end
    end

    return if tiers.any? { |tier| tier[:upto].nil? }

    raise InvalidSplit, "last tier must be open ended to cover any amount"
  end
end
