# O lastro do lançamento: sem o arquivo, o gasto é só uma declaração.
#
# Polimórfico porque o mesmo comprovante serve para um lançamento contábil e
# para um post do feed. Uma tabela só, não duas.
#
# institution_id fica explícito mesmo sendo derivável pelo attachable: sem ele,
# filtrar os documentos do tenant exigiria passar por join em duas tabelas
# diferentes, e o filtro de tenant é o caminho mais executado da aplicação.
#
# A regra do "outro": kind é enum fechado, e kind_detail só é aceito quando kind
# é 'outro'. A check constraint é do mesmo lado que a do domínio, porque a
# instituição digita isso num formulário e o erro tem de aparecer no banco
# também, não só no Aggregate.
class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.bigint :institution_id, null: false
      t.string :attachable_type, null: false
      t.bigint :attachable_id, null: false
      t.string :kind, null: false
      # Só preenchido quando kind = 'outro'. Instituições usam vocabulário
      # próprio e forçar tudo no enum faria a maioria cair em "outro".
      t.string :kind_detail
      t.string :number
      t.date :issued_on

      t.timestamps
    end

    add_foreign_key :documents, :institutions

    add_index :documents, [ :attachable_type, :attachable_id ]
    add_index :documents, [ :institution_id, :issued_on ]
    add_index :documents, [ :institution_id, :kind ]

    add_check_constraint :documents,
      "attachable_type IN ('LedgerEntry', 'Post')",
      name: "documents_attachable_type_check"

    add_check_constraint :documents,
      "kind IN ('nota_fiscal', 'recibo', 'contrato', 'extrato', 'comprovante_pix', " \
      "'relatorio', 'declaracao', 'foto', 'outro')",
      name: "documents_kind_check"

    # A válvula de escape dos dois lados: 'outro' sem descrição não classifica
    # nada, e descrição fora de 'outro' é texto solto.
    add_check_constraint :documents,
      "(kind = 'outro' AND kind_detail IS NOT NULL AND length(btrim(kind_detail)) > 0) " \
      "OR (kind <> 'outro' AND kind_detail IS NULL)",
      name: "documents_kind_detail_check"
  end
end
