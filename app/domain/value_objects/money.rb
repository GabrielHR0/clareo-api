class Money
  include Comparable

  CURRENCY = "BRL"
  SCALE = 2

  attr_reader :amount

  class << self
    def build(value)
      case value
      when Money then value
      when BigDecimal then new(value)
      when Integer, Float, String then new(BigDecimal(value.to_s))
      else
        raise ArgumentError, "cannot build Money from #{value.class}"
      end
    end

    def zero
      new(BigDecimal("0"))
    end

    def brl(value)
      new(BigDecimal(value.to_s))
    end
  end

  def initialize(amount)
    @amount = scale(amount)
  end

  def +(other)
    Money.build(amount + coerce(other))
  end

  def -(other)
    Money.build(amount - coerce(other))
  end

  def *(other)
    Money.build(amount * coerce(other))
  end

  # Percentage of this amount. Percentage is already scaled to 4 decimals.
  def percentage_of(percentage)
    Money.build((amount * percentage.value) / BigDecimal(100))
  end

  def zero?
    amount.zero?
  end

  def positive?
    amount.positive?
  end

  def negative?
    amount.negative?
  end

  def ==(other)
    other.is_a?(Money) && amount == other.amount
  end
  alias eql? ==

  def <=>(other)
    return nil unless other.is_a?(Money)

    amount <=> other.amount
  end

  def to_s
    format("%.#{SCALE}f", amount)
  end

  def inspect
    "#<Money #{self} #{CURRENCY}>"
  end

  private

  def coerce(value)
    value.is_a?(Money) ? value.amount : BigDecimal(value.to_s)
  end

  def scale(value)
    value.round(SCALE)
  end
end
