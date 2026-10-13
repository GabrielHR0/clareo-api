# Centro de custo: separa o mesmo gasto entre projetos. É o que a governança
# chama de rastreabilidade — "dos R$ 10 mil da campanha, quanto foi para
# material e quanto para pessoal?".
#
# Opcional: um lançamento sem centro de custo é válido, porque instituição
# pequena não sempre consegue classificar. O que não é válido é um centro de
# custo que não pertence à instituição que o usa.
class CostCenter
  attr_reader :id, :institution_id, :code, :name

  class << self
    def build(institution_id:, code:, name:, id: nil)
      new(id: id, institution_id: institution_id, code: code, name: name)
    end
  end

  def initialize(institution_id:, code:, name:, id: nil)
    @id = id
    @institution_id = institution_id
    @code = normalize_code(code)
    @name = presence(name, "name")

    validate!
  end

  def ==(other)
    other.is_a?(CostCenter) && institution_id == other.institution_id && code == other.code
  end
  alias eql? ==

  def inspect
    "#<CostCenter #{code} #{name}>"
  end

  private

  def normalize_code(code)
    return nil if code.nil?

    cleaned = code.to_s.strip.tr(" \t", "")
    presence(cleaned, "code")
  end

  def presence(value, field)
    text = value.to_s.strip
    raise InvalidCostCenter, "#{field} cannot be blank" if text.empty?

    text
  end

  def validate!
    return unless institution_id.nil?

    raise InvalidCostCenter, "institution is required"
  end
end
