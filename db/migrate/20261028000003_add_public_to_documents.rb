class AddPublicToDocuments < ActiveRecord::Migration[8.1]
  def change
    # Privado por padrão: a instituição decide o que do comprovante vira público.
    add_column :documents, :public, :boolean, null: false, default: false
    add_index :documents, [ :institution_id, :public ]
  end
end
