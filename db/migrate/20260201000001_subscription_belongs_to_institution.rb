# A assinatura passou a ser por instituição, não por usuário. Um usuário pode
# abrir várias instituições, mas cada uma tem a sua própria assinatura: o plano
# é cobrado porTenant, não por dono.
#
# Isso elimina a cota max_institutions, que existia só para limitar quantas
# instituições um usuário podia abrir com uma assinatura. Com uma assinatura por
# instituição, o número de instituições deixa de ser uma cota e passa a ser uma
# quantidade de assinaturas.
class SubscriptionBelongsToInstitution < ActiveRecord::Migration[8.1]
  def up
    add_column :subscriptions, :institution_id, :bigint
    add_index :subscriptions, :institution_id
    add_foreign_key :subscriptions, :institutions

    # Uma assinatura ativa por instituição. Nomeia a regra, como já fazia o
    # índice por usuário que este substitui.
    remove_index :subscriptions, name: "idx_subscriptions_one_active_per_user"
    add_index :subscriptions, [ :institution_id ],
      name: "idx_subscriptions_one_active_per_institution",
      unique: true,
      where: "status = 'active'"

    # O índice antigo por user_id sai junto. A única forma de ainda consultar
    # assinatura por usuário é via a instituição, que é o caminho do domínio.
    remove_index :subscriptions, name: "index_subscriptions_on_user_id"
    remove_column :subscriptions, :user_id
  end

  def down
    add_column :subscriptions, :user_id, :bigint
    add_index :subscriptions, :user_id
    add_reference :subscriptions, :user, foreign_key: true

    add_index :subscriptions, [ :user_id ],
      name: "idx_subscriptions_one_active_per_user",
      unique: true,
      where: "status = 'active'"

    remove_index :subscriptions, name: "idx_subscriptions_one_active_per_institution"
    remove_index :subscriptions, name: "index_subscriptions_on_institution_id"
    remove_foreign_key :subscriptions, :institutions
    remove_column :subscriptions, :institution_id
  end
end
