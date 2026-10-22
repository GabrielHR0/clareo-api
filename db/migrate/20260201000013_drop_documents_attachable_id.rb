# attachable_id sai: com ledger_entry_id e post_id passando a ser as FK de
# verdade, manter o id antigo era ter duas fontes para o mesmo dado, e a segunda
# diverge em silêncio.
#
# attachable_type continua, porque é útil para ler e indexar sem lidar com duas
# colunas nullable — mas é derivada e não é consultada como verdade. A verdade é
# a coluna de FK, e é dela que a view deriva o tipo.
class DropDocumentsAttachableId < ActiveRecord::Migration[8.1]
  def up
    remove_column :documents, :attachable_id
  end

  def down
    add_column :documents, :attachable_id, :bigint
    execute <<~SQL
      UPDATE documents
         SET attachable_id = COALESCE(ledger_entry_id, post_id)
    SQL
  end
end
