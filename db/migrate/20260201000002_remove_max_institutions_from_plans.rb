# O plano é cobrado por instituição, não por usuário. Por isso a cota
# max_institutions sai: ela existia só para limitar quantas instituições um
# usuário podia abrir com uma assinatura, e com uma assinatura por instituição
# o número de instituições deixou de ser uma cota.
#
# O que diferencia enterprise de pro agora é volume de transações e preço,
# decisão que ainda não foi tomada. A coluna features permanece: é texto de
# apresentação, lido no marketing e nunca consultado pelo domínio para autorizar
# nada.
class RemoveMaxInstitutionsFromPlans < ActiveRecord::Migration[8.1]
  def up
    remove_column :plans, :max_institutions
  end

  def down
    add_column :plans, :max_institutions, :integer
  end
end
