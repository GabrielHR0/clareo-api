# A cota max_institutions saiu junto com a assinatura por usuário: com uma
# assinatura por instituição, o número de instituições deixou de ser uma cota.
# O plano agora responde "quanto custa e o que inclui", e não "quantas
# instituições cabem".
class Plan
  TIERS = %i[free pro enterprise].freeze

  attr_reader :code, :name, :price, :features

  class << self
    def build(code:, name:, price:, features: [])
      new(code: code, name: name, price: price, features: features)
    end
  end

  def initialize(code:, name:, price:, features: [])
    @code = code
    @name = name
    @price = Money.build(price)
    @features = features

    validate!
  end

  def free?
    price.zero?
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
    end
end
