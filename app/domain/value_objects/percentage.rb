class Percentage
  include Comparable

  SCALE = 4
  LIMIT = BigDecimal(100)

  attr_reader :value

  class << self
    def build(value)
      return value if value.is_a?(Percentage)

      new(decimalize(value))
    end

    def sum(percentages)
      build(percentages.sum { |percentage| decimalize(percentage) })
    end

    def decimalize(value)
      case value
      when Percentage then value.value
      when BigDecimal then value
      when Integer, Float, String then BigDecimal(value.to_s)
      else
        raise ArgumentError, "cannot build Percentage from #{value.class}"
      end
    end
  end

  def initialize(value)
    @value = scale(value)
    validate!
  end

  def +(other)
    self.class.build(value + self.class.decimalize(other))
  end

  def -(other)
    self.class.build(value - self.class.decimalize(other))
  end

  def zero?
    value.zero?
  end

  def full?
    value == LIMIT
  end

  def complement
    self.class.build(LIMIT - value)
  end

  def ==(other)
    other.is_a?(Percentage) && value == other.value
  end
  alias eql? ==

  def <=>(other)
    return nil unless other.is_a?(Percentage)

    value <=> other.value
  end

  def to_s
    format("%.#{SCALE}f", value)
  end

  def inspect
    "#<Percentage #{self}%>"
  end

  private

  def scale(value)
    value.round(SCALE)
  end

  def validate!
    raise InvalidSplit, "percentage cannot be negative" if value.negative?
    raise InvalidSplit, "percentage cannot exceed 100" if value > LIMIT
  end
end
