# documents.attachable_type/attachable_id viram duas colunas com foreign key.
#
# Associação polimórfica não tem FK no Rails, e o schema anterior era só
# check constraint em string: o banco aceitaria um documento apontando para uma
# linha que não existe. Num produto em que o comprovante é o lastro da prestação
# de contas, isso precisa ser integridade de verdade.
#
# Duas colunas mais um CHECK de exatamente-uma-preenchida dão isso numa tabela
# só, sem trigger. LedgerEntry e Post acabaram de existir em 000008 e 000009,
# então a FK já pode ser criada aqui.
#
# attachable_type fica, derivado das colunas pela view, porque o log e o feed
# consultam por tipo e ler duas colunas nullable em todo lugar é pior.
class DocumentsAttachWithRealForeignKeys < ActiveRecord::Migration[8.1]
  def up
    add_column :documents, :ledger_entry_id, :bigint
    add_column :documents, :post_id, :bigint

    add_foreign_key :documents, :ledger_entries, column: :ledger_entry_id
    add_foreign_key :documents, :posts, column: :post_id

    # Migra as linhas existentes para a coluna que agora é a FK de verdade.
    execute <<~SQL
      UPDATE documents
         SET ledger_entry_id = attachable_id
       WHERE attachable_type = 'LedgerEntry'
    SQL
    execute <<~SQL
      UPDATE documents
         SET post_id = attachable_id
       WHERE attachable_type = 'Post'
    SQL

    # Uma linha sem alvo ou apontando para os dois não pode sobreviver.
    execute "DELETE FROM documents WHERE ledger_entry_id IS NULL AND post_id IS NULL"
    execute "DELETE FROM documents WHERE ledger_entry_id IS NOT NULL AND post_id IS NOT NULL"

    add_check_constraint :documents,
      "(ledger_entry_id IS NOT NULL AND post_id IS NULL) OR (ledger_entry_id IS NULL AND post_id IS NOT NULL)",
      name: "documents_exactly_one_attachable_check"

    add_index :documents, [ :ledger_entry_id ]
    add_index :documents, [ :post_id ]

    # attachable_type fica, derivado das colunas pela view. O índice antigo era
    # (attachable_type, attachable_id); o novo par é por coluna, porque o filtro
    # real é "documentos deste lançamento" ou "deste post".
    remove_index :documents, name: "index_documents_on_attachable_type_and_attachable_id"
    remove_check_constraint :documents, name: "documents_attachable_type_check"
  end

  def down
    add_check_constraint :documents,
      "attachable_type IN ('LedgerEntry', 'Post')",
      name: "documents_attachable_type_check"
    add_index :documents, [ :attachable_type, :attachable_id ]

    remove_check_constraint :documents, name: "documents_exactly_one_attachable_check"
    remove_index :documents, [ :ledger_entry_id ]
    remove_index :documents, [ :post_id ]

    remove_foreign_key :documents, column: :ledger_entry_id
    remove_foreign_key :documents, column: :post_id
    remove_column :documents, :ledger_entry_id
    remove_column :documents, :post_id
  end
end
