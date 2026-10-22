# Onde o comprovante se liga: um lançamento contábil ou um post do feed.
#
# Poderia ser attachable_type/attachable_id polimórfico, que é o jeito que o
# Rails faz. Mas associação polimórfica não tem foreign key: o banco aceitaria
# um documento apontando para uma linha que não existe, e ninguém descobriria
# até alguém procurar o comprovante de uma prestação de contas. Num produto em
# que o comprovante é o lastro, isso não é detalhe.
#
# Duas colunas e uma check constraint dão integridade de verdade numa tabela
# só, sem trigger. O custo é que o domínio precisa saber que existe mais de um
# alvo, e é por isso que isto é um value object e não dois campos soltos: a
# coerência — exatamente um dos dois — fica num lugar só.
class DocumentTarget
  LEDGER_ENTRY = "LedgerEntry"
  POST = "Post"

  attr_reader :ledger_entry_id, :post_id

  class << self
    def for_ledger_entry(ledger_entry_id)
      new(ledger_entry_id: ledger_entry_id)
    end

    def for_post(post_id)
      new(post_id: post_id)
    end

    # Reconstrói a partir das colunas do record, para a ida e a volta manterem a
    # mesma coerência.
    def build(ledger_entry_id: nil, post_id: nil)
      new(ledger_entry_id: ledger_entry_id, post_id: post_id)
    end
  end

  def initialize(ledger_entry_id: nil, post_id: nil)
    @ledger_entry_id = ledger_entry_id
    @post_id = post_id

    validate!
  end

  def ledger_entry?
    !ledger_entry_id.nil?
  end

  def post?
    !post_id.nil?
  end

  # A mesma resposta que o chamador usa para filtrar, e o valor que vai para a
  # coluna documents.attachable_type, para o log e o feed não precisarem
  # repetir a tabela dos dois casos.
  def type_name
    ledger_entry? ? LEDGER_ENTRY : POST
  end

  def target_id
    ledger_entry? ? ledger_entry_id : post_id
  end

  def ==(other)
    other.is_a?(DocumentTarget) &&
      ledger_entry_id == other.ledger_entry_id && post_id == other.post_id
  end
  alias eql? ==

  def inspect
    "#<DocumentTarget #{type_name}##{target_id}>"
  end

  private

  def validate!
    if ledger_entry_id.nil? && post_id.nil?
      raise InvalidDocument, "a document needs a ledger entry or a post"
    end

    return if ledger_entry_id.nil? || post_id.nil?

    raise InvalidDocument, "a document cannot attach to both a ledger entry and a post"
  end
end
