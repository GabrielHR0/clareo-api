# Resumo financeiro derivado do razão. Não é cache: cada leitura recalcula a
# partir dos lançamentos posted, porque o número que vale é o que está no
# ledger, não uma cópia que envelhece.
class FinancialSummary
  attr_reader :donation_income, :declared_income, :expense

  class << self
    def build(donation_income: 0, declared_income: 0, expense: 0)
      new(
        donation_income: donation_income,
        declared_income: declared_income,
        expense: expense
      )
    end
  end

  def initialize(donation_income:, declared_income:, expense:)
    @donation_income = Money.build(donation_income)
    @declared_income = Money.build(declared_income)
    @expense = Money.build(expense)
  end

  def total_income
    donation_income + declared_income
  end

  def balance
    total_income - expense
  end

  def ==(other)
    other.is_a?(FinancialSummary) &&
      donation_income == other.donation_income &&
      declared_income == other.declared_income &&
      expense == other.expense
  end
  alias eql? ==

  def inspect
    "#<FinancialSummary income=#{total_income} expense=#{expense} balance=#{balance}>"
  end
end
