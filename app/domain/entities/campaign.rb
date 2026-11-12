# Campanha de arrecadação com destino de recurso.
#
# O ponto que importa: a campanha NÃO guarda o quanto já arrecadou. current_amount
# no banco é cache que dessincroniza e vira mentira silenciosa — se o split for
# estornado, a meta continua anunciando um valor que não existe mais. Arrecadado
# e aplicado são derivados dos lançamentos:
#
#   raised  = soma de ledger_entries origin=donation, kind=income
#   applied = soma de ledger_entries origin=declared, kind=expense
#
# Só guardamos a meta e o período. O progresso é resposta de consulta.
class Campaign
  STATUSES = %i[active paused closed].freeze

  attr_reader :id, :institution_id, :title, :description, :goal, :starts_on, :ends_on, :status

  class << self
    def build(institution_id:, title:, description:, goal:, starts_on:, ends_on:,
              status: :active, id: nil)
      new(
        institution_id: institution_id,
        title: title,
        description: description,
        goal: goal,
        starts_on: starts_on,
        ends_on: ends_on,
        status: status,
        id: id
      )
    end
  end

  def initialize(id: nil, institution_id:, title:, description:, goal:, starts_on:,
                 ends_on:, status: :active)
    @id = id
    @institution_id = institution_id
    @title = presence(title, "title")
    @description = presence(description, "description")
    @goal = Money.build(goal)
    @starts_on = starts_on
    @ends_on = ends_on
    @status = status.to_sym

    validate!
  end

  def active?
    status == :active
  end

  def paused?
    status == :paused
  end

  def closed?
    status == :closed
  end

  # Pausada some do feed público: a instituição deixou de querer captação, e
  # exibir a meta continuando a subir contradiz isso. Fechada mantém os
  # números finais visíveis, porque prestação de contas não se apaga.
  def in_public_feed?
    active?
  end

  # Uma campanha que passou da data final não aceita mais doação, mesmo
  # continuando marcada como active.
  def expired?(today = Date.today)
    !ends_on.nil? && ends_on < today
  end

  # Quanto foi arrecadado é pergunta de consulta, não do agregado: a entidade
  # sabe a meta, o ledger sabe o valor. Não há método de progresso aqui.
  def pause!
    transition_to!(%i[active], :paused)
    self
  end

  def resume!
    transition_to!(%i[paused], :active)
    self
  end

  # Encerrar é sempre possível a partir de active ou paused: a instituição
  # encerra quando quiser, e o prazo é uma restrição de dados, não uma imposição.
  def close!
    transition_to!(%i[active paused], :closed)
    self
  end

  def ==(other)
    other.is_a?(Campaign) && id == other.id && institution_id == other.institution_id
  end
  alias eql? ==

  def inspect
    "#<Campaign #{title} #{status} goal=#{goal}>"
  end

  private

  def presence(value, field)
    text = value.to_s.strip
    raise InvalidCampaign, "#{field} cannot be blank" if text.empty?

    text
  end

  def validate!
    raise InvalidCampaign, "institution is required" if institution_id.nil?

    if goal.negative? || goal.zero?
      raise InvalidCampaign, "goal must be greater than zero"
    end

    unless STATUSES.include?(status)
      raise InvalidCampaign, "status must be one of #{STATUSES.join(', ')}"
    end

    return if starts_on.nil? || ends_on.nil?

    raise InvalidCampaign, "ends_on cannot be before starts_on" if ends_on < starts_on
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidCampaign, "cannot move campaign from #{status} to #{target}"
    end

    @status = target
  end
end
