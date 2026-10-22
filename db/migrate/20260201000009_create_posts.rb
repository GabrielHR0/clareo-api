# Narrativa do feed. Publicação imediata, sem rascunho e sem aprovação: o post
# é comunicação da instituição, e quem aprova prestação de contas é o admin, em
# AccountabilityReport.
#
# status hidden em vez de deleted_at: o post pode ter sido citado por um
# lançamento ou por um documento, e sumir com ele deixaria a referência órfã sem
# explicação.
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.bigint :institution_id, null: false
      t.string :title, null: false
      t.text :content, null: false
      t.string :post_type, null: false, default: "update"
      t.string :status, null: false, default: "published"
      t.datetime :published_at

      t.timestamps
    end

    add_foreign_key :posts, :institutions

    # Índice do feed: por instituição, do mais recente para o mais antigo.
    add_index :posts, [ :institution_id, :published_at ]
    add_index :posts, [ :institution_id, :status ]
    add_index :posts, [ :institution_id, :post_type ]

    add_check_constraint :posts,
      "post_type IN ('update', 'report')",
      name: "posts_post_type_check"

    add_check_constraint :posts,
      "status IN ('published', 'hidden')",
      name: "posts_status_check"
  end
end
