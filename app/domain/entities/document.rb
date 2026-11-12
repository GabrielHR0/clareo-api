# O lastro do lançamento. A governança não aceita "gastei R$ 400 em material"
# sem o que prova isso; por isso o comprovante é parte do modelo, não um extra.
#
# O kind é enum fechado com uma válvula de escape: instituições usam
# vocabulário próprio, e forçar tudo dentro de nove valores faria a instituição
# classificar como "outro" a maioria dos documentos. A válvula é 'outro' mais
# kind_detail, que a instituição preenche. A regra é dura e dos dois lados:
# 'outro' sem descrição não diz nada, e descrição sem 'outro' é texto solto sem
# dono.
class Document
  KINDS = %i[
    nota_fiscal
    recibo
    contrato
    extrato
    comprovante_pix
    relatorio
    declaracao
    foto
    outro
  ].freeze

  # O valor que exige preenchimento manual do tipo real.
  OTHER = :outro

  # LedgerEntry e Post viraram tabelas de verdade em 9C e 9D, então documents
  # tem duas colunas de FK de verdade em vez de um par polimórfico sem
  # integridade. A coerência — exatamente um dos dois — é garantida aqui e pela
  # check constraint documents_exactly_one_attachable_check.
  attr_reader :id, :institution_id, :target, :kind, :kind_detail, :number, :issued_on

  class << self
    def build(institution_id:, target:, kind:, kind_detail: nil, number: nil,
              issued_on: nil, public: false, id: nil)
      new(
        id: id,
        institution_id: institution_id,
        target: target,
        kind: kind,
        kind_detail: kind_detail,
        number: number,
        issued_on: issued_on,
        public: public
      )
    end
  end

  def initialize(id: nil, institution_id:, target:, kind:,
                 kind_detail: nil, number: nil, issued_on: nil, public: false)
    @id = id
    @institution_id = institution_id
    @target = target.is_a?(DocumentTarget) ? target : DocumentTarget.build(target)
    @kind = kind.to_sym
    @kind_detail = kind_detail.nil? ? nil : kind_detail.to_s.strip
    @number = number.nil? ? nil : number.to_s.strip
    @issued_on = issued_on
    @public = public == true

    validate!
  end

  # O comprovante é privado por padrão. Expor nota fiscal ou recibo com dado
  # pessoal é decisão explícita da instituição, não efeito colateral do feed.
  def public?
    @public
  end

  def other?
    kind == OTHER
  end

  # O alvo, para quem precisar do id sem desempacotar o DocumentTarget.
  def attachable_id
    target.target_id
  end

  def attachable_type
    target.type_name
  end

  def for_ledger_entry?
    target.ledger_entry?
  end

  def for_post?
    target.post?
  end

  # O tipo real, seja do enum seja o que a instituição escreveu. É o que o
  # relatório usa para agrupar.
  def effective_kind
    other? ? kind_detail : kind.to_s
  end

  def ==(other)
    other.is_a?(Document) && id == other.id && institution_id == other.institution_id
  end
  alias eql? ==

  def inspect
    "#<Document #{kind}#{other? ? "(#{kind_detail})" : ''} ##{number}>"
  end

  private

  def validate!
    raise InvalidDocument, "institution is required" if institution_id.nil?

    unless KINDS.include?(kind)
      raise InvalidDocument, "kind must be one of #{KINDS.join(', ')}"
    end

    validate_kind_detail!
  end

  # 'outro' só vale com descrição: sem ela o documento não está classificado.
  # E descrição fora de 'outro' é texto solto, que é o que o enum fechado
  # existe para impedir.
  def validate_kind_detail!
    if other?
      raise InvalidDocument, "kind_detail is required when kind is outro" if kind_detail.to_s.empty?
    elsif !kind_detail.nil?
      raise InvalidDocument, "kind_detail is only allowed when kind is outro"
    end
  end
end
