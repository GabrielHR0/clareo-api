module Api
  module V1
    module Serializers
      class FinancialSummarySerializer
        def self.call(summary)
          {
            donation_income_brl: summary.donation_income.to_s,
            declared_income_brl: summary.declared_income.to_s,
            expense_brl: summary.expense.to_s,
            total_income_brl: summary.total_income.to_s,
            balance_brl: summary.balance.to_s
          }
        end
      end
    end
  end
end
