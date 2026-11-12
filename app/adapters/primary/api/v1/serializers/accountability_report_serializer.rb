module Api
  module V1
    module Serializers
      class AccountabilityReportSerializer
        def self.call(report, documents_by_ledger_entry: {}, include_entries: true)
          payload = {
            id: report.id,
            institution_id: report.institution_id,
            campaign_id: report.campaign_id,
            title: report.title,
            summary: report.summary,
            period_start: report.period_start&.iso8601,
            period_end: report.period_end&.iso8601,
            status: report.status.to_s,
            submitted_at: report.submitted_at&.iso8601,
            review_started_at: report.review_started_at&.iso8601,
            approved_at: report.approved_at&.iso8601,
            published_at: report.published_at&.iso8601,
            review_opinion: report.review_opinion,
            review_notes: report.review_notes,
            total_income_brl: report.total_income.to_s,
            total_expense_brl: report.total_expense.to_s,
            balance_brl: report.balance.to_s
          }

          if include_entries
            payload[:entries] = report.entries.map do |entry|
              AccountabilityReportEntrySerializer.call(
                entry,
                documents: documents_by_ledger_entry.fetch(entry.ledger_entry_id, [])
              )
            end
          end

          payload
        end
      end
    end
  end
end
