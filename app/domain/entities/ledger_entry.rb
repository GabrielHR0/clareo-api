# Um lançamento do razão contábil da instituição. É a peça que separa
# transparência auditável de formulário em branco.
#
# A regra que governa o modelo inteiro: o número tem dono diferente da narrativa.
# Receita de doação é fato do sistema (origin: donation), despesa é declaração da
# instituição (origin: declared), e o texto nunca substitui o número.
#
# Razão de uma via: a entrada tem conta contábil, valor, data e natureza, mas não
# há débito e crédito. É o formato da DOAR, que é o padrão brasileiro de
# prestação de contas.
class LedgerEntry
  KINDS = %i[income expense].freeze

  # donation: o sistema sabe, porque o split foi liquidado pelo webhook.
  # declared: a instituição escreveu.
  ORIGINS = %i[donation declared].freeze
  SYSTEM_ORIGIN = :donation

  STATUSES = %i[draft posted voided].freeze

  attr_reader :id, :institution_id, :account_id, :cost_center_id, :campaign_id,
              :kind, :origin, :amount, :description, :status,
              :donation_split_id, :void_reason, :posted_on

  class << self
    # Entrada de receita que o sistema cria a partir de um split liquidado.
    # Não recebe kind nem status: são consequência da origem.
    def from_donation_split(institution_id:, donation_split_id:, account_id:,
                            amount:, posted_on:, campaign_id: nil, cost_center_id: nil,
                            description: nil, id: nil)
      new(
        id: id,
        institution_id: institution_id,
        account_id: account_id,
        cost_center_id: cost_center_id,
        campaign_id: campaign_id,
        kind: :income,
        origin: SYSTEM_ORIGIN,
        amount: amount,
        description: description,
        status: :posted,
        donation_split_id: donation_split_id,
        posted_on: posted_on,
        immutable: true
      )
    end

    def build(institution_id:, kind:, amount:, description: nil, account_id: nil,
              cost_center_id: nil, campaign_id: nil, posted_on: nil,
              status: :draft, donation_split_id: nil, void_reason: nil, id: nil)
      new(
        institution_id: institution_id,
        account_id: account_id,
        cost_center_id: cost_center_id,
        campaign_id: campaign_id,
        kind: kind,
        origin: :declared,
        amount: amount,
        description: description,
        status: status,
        donation_split_id: donation_split_id,
        void_reason: void_reason,
        posted_on: posted_on,
        id: id
      )
    end
  end

  def initialize(id: nil, institution_id:, kind:, origin:, amount:, description: nil,
                 status: :draft, account_id: nil, cost_center_id: nil, campaign_id: nil,
                 posted_on: nil, donation_split_id: nil, void_reason: nil, immutable: false)
    @id = id
    @institution_id = institution_id
    @account_id = account_id
    @cost_center_id = cost_center_id
    @campaign_id = campaign_id
    @kind = kind.to_sym
    @origin = origin.to_sym
    @amount = Money.build(amount)
    @description = normalize_description(description)
    @status = status.to_sym
    @donation_split_id = donation_split_id
    @void_reason = normalize_description(void_reason)
    @posted_on = posted_on
    @immutable = immutable

    validate!
  end

  def system?
    origin == SYSTEM_ORIGIN
  end

  def declared?
    origin == :declared
  end

  def income?
    kind == :income
  end

  def expense?
    kind == :expense
  end

  def posted?
    status == :posted
  end

  def voided?
    status == :voided
  end

  def draft?
    status == :draft
  end

  # Uma entrada de sistema é fato consumado: o webhook do provedor já liquidou o
  # dinheiro, e reescrever esse número é reescrever o que o banco registrou.
  # Por isso não tem setter e nem aparece na edição da instituição.
  def editable?
    !system?
  end

  def post!(on: nil)
    transition_to!(%i[draft], :posted)
    @posted_on = on if on
    self
  end

  # Estorna, nunca apaga. Razão contábil não se corrige por UPDATE: a correção é
  # um lançamento novo que anula o anterior, e o anterior fica no histórico.
  #
  # Entrada de sistema não é anulável: o webhook já liquidou o dinheiro, e
  # estornar o lançamento apagaria do razão o fato de que ele entrou. A
  # correção de um split é evento do próprio(split, não deste lançamento.
  #
  # A justificativa é validada antes da transição, não depois: mutar o status e
  # só então descobrir que o motivo era vazio deixaria o lançamento estornado sem
  # motivo, que é exatamente o estado que o razão não pode ter.
  def void!(reason:)
    if system?
      raise InvalidLedgerEntry, "a donation entry cannot be voided"
    end

    text = normalize_description(reason)
    raise InvalidLedgerEntry, "void_reason is required when voided" if text.nil?

    transition_to!(%i[draft posted], :voided)
    @void_reason = text
    self
  end

  def ==(other)
    other.is_a?(LedgerEntry) && id == other.id && institution_id == other.institution_id
  end
  alias eql? ==

  def inspect
    "#<LedgerEntry #{kind} #{amount} (#{origin}/#{status})>"
  end

  private

  def normalize_description(value)
    return nil if value.nil?

    text = value.to_s.strip
    text.empty? ? nil : text
  end

  def validate!
    raise InvalidLedgerEntry, "institution is required" if institution_id.nil?
    raise InvalidLedgerEntry, "amount cannot be negative" if amount.negative?

    unless KINDS.include?(kind)
      raise InvalidLedgerEntry, "kind must be one of #{KINDS.join(', ')}"
    end

    unless ORIGINS.include?(origin)
      raise InvalidLedgerEntry, "origin must be one of #{ORIGINS.join(', ')}"
    end

    unless STATUSES.include?(status)
      raise InvalidLedgerEntry, "status must be one of #{STATUSES.join(', ')}"
    end

    validate_origin_shape!
    validate_immutability!
    validate_void_reason!
  end

  # Receita do sistema é sempre income, sempre com split, e sem campanha: a
  # campanha vem do split e a instituição não escolhe para onde o dinheiro foi.
  def validate_origin_shape!
    unless system?
      if !donation_split_id.nil?
        raise InvalidLedgerEntry, "donation_split_id is only allowed on donation entries"
      end

      return
    end

    unless kind == :income
      raise InvalidLedgerEntry, "donation entries must be income"
    end

    raise InvalidLedgerEntry, "donation entries require a donation_split_id" if donation_split_id.nil?
  end

  # Só uma entrada de sistema é mutável de verdade. Uma de sistema nunca sai de
  # posted, e uma declarada nunca volta de voided: o estorno é fato consumado
  # também, e desfazê-lo apagaria o histórico do porquê.
  def validate_immutability!
    if @immutable && status != :posted
      raise InvalidLedgerEntry, "donation entries cannot leave posted"
    end

    return unless @immutable && voided?

    raise InvalidLedgerEntry, "donation entries cannot be voided"
  end

  def validate_void_reason!
    return unless status == :voided && void_reason.nil?

    raise InvalidLedgerEntry, "void_reason is required when voided"
  end

  def transition_to!(allowed_from, target)
    unless allowed_from.include?(status)
      raise InvalidLedgerEntry, "cannot move ledger entry from #{status} to #{target}"
    end

    @status = target
  end
end
