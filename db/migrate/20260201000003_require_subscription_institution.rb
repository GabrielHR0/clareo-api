# A assinatura pertence à instituição, sem exceção: institution_id não pode ser
# nulo. A coluna entrou nullable na migration anterior porque o PostgreSQL não
# aceita adicionar coluna NOT NULL a uma tabela que já tem linhas, e a linha
# herdada do modelo por usuário ficou órfã no caminho.
#
# Nullable era um buraco de verdade, não só feio: o índice único parcial trata
# NULLs como distintos entre si, então duas assinaturas ativas sem instituição
# passariam sem reclamar. A coluna precisa ser NOT NULL para o índice
# implementar a regra de verdade.
class RequireSubscriptionInstitution < ActiveRecord::Migration[8.1]
  def up
    # A linha que sobrou da assinatura por usuário não pertence a ninguém
    # agora: apontava para o usuário, coluna que não existe mais. Sem
    # institution_id ela não é recuperável, e o seed a recria por instituição.
    execute "DELETE FROM subscriptions WHERE institution_id IS NULL"

    change_column_null :subscriptions, :institution_id, false
  end

  def down
    change_column_null :subscriptions, :institution_id, true
  end
end
