# Catálogo padrão de contas, semeado em cada instituição.
#
# Isto é conteúdo de domínio, não configuração: é o conjunto de categorias que
# uma organização sem fins lucrativos precisa para prestar contas. Por isso mora
# em app/domain/services e não em config.
#
# A estrutura segue a ordem de grupos da DOAR — Demonstração de Origem e
# Aplicação de Recursos, que é o formato brasileiro de prestação de contas. Só
# receitas e despesas, sem patrimônio: a prestação de contas que o produto
# publica é de fluxo, e grupo de resultado já basta. Razão de uma via, com conta
# de classificação, não com débito e crédito.
class AccountTemplate
  # A receita de doação é system: true e tem código estável, porque a receita
  # automática do split aponta para ela por código. Se alguém renomear ou
  # desativar essa conta, a conciliação perde a âncora.
  DONATION_INCOME_CODE = "1.1"

  ACCOUNTS = [
    { code: "1",   name: "Receitas de Doações",              nature: :income,  parent_code: nil, system: false },
    { code: "1.1", name: "Receitas de Doações",              nature: :income,  parent_code: "1", system: true },
    { code: "1.2", name: "Receitas de Campanhas",            nature: :income,  parent_code: "1", system: false },
    { code: "2",   name: "Receitas de Subvenções",           nature: :income,  parent_code: nil, system: false },
    { code: "2.1", name: "Convênios e Termos de Fomento",   nature: :income,  parent_code: "2", system: false },
    { code: "2.2", name: "Doações Internacionais",           nature: :income,  parent_code: "2", system: false },
    { code: "3",   name: "Receitas Financeiras",            nature: :income,  parent_code: nil, system: false },
    { code: "3.1", name: "Rendimentos de Aplicação",        nature: :income,  parent_code: "3", system: false },
    { code: "4",   name: "Outras Receitas",                  nature: :income,  parent_code: nil, system: false },

    { code: "5",   name: "Despesas com Materiais",          nature: :expense, parent_code: nil, system: false },
    { code: "5.1", name: "Material de Consumo",             nature: :expense, parent_code: "5", system: false },
    { code: "5.2", name: "Material Permanente",             nature: :expense, parent_code: "5", system: false },
    { code: "6",   name: "Despesas com Pessoal",            nature: :expense, parent_code: nil, system: false },
    { code: "6.1", name: "Remuneração e Encargos",           nature: :expense, parent_code: "6", system: false },
    { code: "6.2", name: "Vale Transporte e Alimentação",   nature: :expense, parent_code: "6", system: false },
    { code: "7",   name: "Despesas com Serviços",            nature: :expense, parent_code: nil, system: false },
    { code: "7.1", name: "Prestação de Serviços",           nature: :expense, parent_code: "7", system: false },
    { code: "7.2", name: "Aluguel e Condomínio",             nature: :expense, parent_code: "7", system: false },
    { code: "7.3", name: "Energia, Água e Internet",         nature: :expense, parent_code: "7", system: false },
    { code: "8",   name: "Despesas com Eventos",             nature: :expense, parent_code: nil, system: false },
    { code: "9",   name: "Despesas Administrativas",        nature: :expense, parent_code: nil, system: false },
    { code: "10",  name: "Despesas com Captação",           nature: :expense, parent_code: nil, system: false }
  ].freeze

  class << self
    def default
      ACCOUNTS
    end

    # Transforma o catálogo em agregados Account prontos para a instituição.
    # Filtrado por nature para quem só quer criar um lado do razão.
    def build_for(institution_id:, nature: nil)
      specs = nature ? ACCOUNTS.select { |spec| spec[:nature] == nature.to_sym } : ACCOUNTS

      specs.map do |spec|
        Account.build(
          institution_id: institution_id,
          code: spec[:code],
          name: spec[:name],
          nature: spec[:nature],
          parent_code: spec[:parent_code],
          system: spec[:system]
        )
      end
    end

    def donation_income?
      ACCOUNTS.any? do |spec|
        spec[:code] == DONATION_INCOME_CODE && spec[:system] && spec[:nature] == :income
      end
    end
  end
end
