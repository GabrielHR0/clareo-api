module Api
  module V1
    module Serializers
      class AccountabilityReportEntrySerializer
        def self.call(entry, documents: [])
          {
            ledger_entry_id: entry.ledger_entry_id,
            account_code: entry.account_code,
            account_name: entry.account_name,
            campaign_id: entry.campaign_id,
            kind: entry.kind.to_s,
            origin: entry.origin.to_s,
            posted_on: entry.posted_on&.iso8601,
            description: entry.description,
            amount_brl: entry.amount.to_s,
            documents: documents.map { |document| DocumentSerializer.call(document) }
          }
        end
      end
    end
  end
end
