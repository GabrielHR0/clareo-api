class DocumentRecord < ApplicationRecord
  self.table_name = "documents"

  belongs_to :institution_record, foreign_key: :institution_id, inverse_of: :document_records

  # Duas FKs de verdade em vez de um par polimórfico. A check constraint
  # documents_exactly_one_attachable_check garante que só uma está preenchida.
  # attachable_type fica por compatibilidade de leitura, mas não é fonte: quem
  # grava preenche as colunas e o banco recusa as combinações inválidas.
  belongs_to :ledger_entry_record,
    foreign_key: :ledger_entry_id,
    inverse_of: :document_records,
    optional: true
  belongs_to :post_record,
    foreign_key: :post_id,
    inverse_of: :document_records,
    optional: true

  # Um documento pode ter mais de um arquivo anexado: a nota fiscal e o
  # comprovante de Pix são dois blobs do mesmo lançamento.
  has_many_attached :files

  ATTACHABLE_TYPES = %w[LedgerEntry Post].freeze
  KINDS = %w[
    nota_fiscal recibo contrato extrato comprovante_pix
    relatorio declaracao foto outro
  ].freeze
  OTHER = "outro"

  validates :attachable_type, inclusion: { in: ATTACHABLE_TYPES }
  validates :kind, inclusion: { in: KINDS }
  validate :exactly_one_attachable
  validate :kind_detail_matches_kind
  validate :target_belongs_to_institution

  scope :other, -> { where(kind: OTHER) }
  scope :typed, -> { where.not(kind: OTHER) }
  scope :publicly_visible, -> { where(public: true) }

  def other?
    kind == OTHER
  end

  def public?
    self[:public]
  end

  private

  # Mesma coerência do DocumentTarget, no lado do banco. As validações não veem
  # a outra requisição; a check constraint vê.
  def exactly_one_attachable
    filled = [ ledger_entry_id, post_id ].compact.size

    return if filled == 1

    errors.add(:base, "a document needs exactly one of ledger_entry_id or post_id")
  end

  # Mesma regra do agregado Document, e pela mesma razão: o formulário manda o
  # usuário escrever, e a mensagem precisa ser boa antes de chegar no banco.
  # if/else em vez de guard clause: `return` dentro de bloco passado a validate
  # levanta LocalJumpError, porque o bloco não é corpo de método.
  def kind_detail_matches_kind
    if kind == OTHER
      if kind_detail.blank? || kind_detail.to_s.strip.empty?
        errors.add(:kind_detail, "is required when kind is outro")
      end
    elsif kind_detail.present?
      errors.add(:kind_detail, "is only allowed when kind is outro")
    end
  end

  def target_belongs_to_institution
    if ledger_entry_record && ledger_entry_record.institution_id != institution_id
      errors.add(:ledger_entry_id, "must belong to the same institution")
    end

    if post_record && post_record.institution_id != institution_id
      errors.add(:post_id, "must belong to the same institution")
    end
  end
end
