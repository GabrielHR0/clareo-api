# Uma conta do plano de contas da instituição. É o que dá sentido ao lançamento:
# "gasto" sem classificação não é prestação de contas, é extrato bancário. Com
# plano de contas, o relatório sai por categoria e a instituição consegue dizer
# onde o dinheiro foi aplicado.
#
# A hierarquia é referenciada por code, não por id, porque o catálogo padrão é
# dado puro e não pode depender de ids que o banco ainda não atribuiu.
class Account
  NATURES = %i[income expense].freeze

  attr_reader :id, :institution_id, :code, :name, :nature, :parent_code, :system

  class << self
    def build(institution_id:, code:, name:, nature:, parent_code: nil, system: false)
      new(
        institution_id: institution_id,
        code: code,
        name: name,
        nature: nature,
        parent_code: parent_code,
        system: system
      )
    end
  end

  def initialize(institution_id:, code:, name:, nature:, parent_code: nil, system: false)
    @institution_id = institution_id
    @code = normalize_code(code)
    @name = presence(name, "name")
    @nature = nature.to_sym
    @parent_code = normalize_code(parent_code)
    @system = system

    validate!
  end

  def income?
    nature == :income
  end

  def expense?
    nature == :expense
  end

  # system: true é conta que veio do catálogo padrão. Não pode ser desativada
  # nem reclassificada, porque a receita automática de doação aponta para uma
  # delas por código.
  def deactivatable?
    !system
  end

  def ==(other)
    other.is_a?(Account) && institution_id == other.institution_id && code == other.code
  end
  alias eql? ==

  def inspect
    "#<Account #{code} #{name} (#{nature})>"
  end

  private

  # O código é a identidade dentro da instituição. Espaços saem porque a
  # instituição digita o código à mão e o relatório agrupa por ele.
  def normalize_code(code)
    return nil if code.nil?

    cleaned = code.to_s.strip.tr(" \t", "")
    presence(cleaned, "code")
  end

  def presence(value, field)
    text = value.to_s.strip
    raise InvalidAccount, "#{field} cannot be blank" if text.empty?

    text
  end

  def validate!
    raise InvalidAccount, "institution is required" if institution_id.nil?

    unless NATURES.include?(nature)
      raise InvalidAccount, "nature must be one of #{NATURES.join(', ')}"
    end

    return unless parent_code == code

    raise InvalidAccount, "account cannot be its own parent"
  end
end
