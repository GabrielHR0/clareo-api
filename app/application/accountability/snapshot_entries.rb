module Accountability
  # Fotografa o razão de um período. É a única passagem de LedgerEntry para
  # AccountabilityReportEntry: nenhum relatório monta entry na mão.
  class SnapshotEntries
    def initialize(ledger_entry_repository:, account_repository:)
      @ledger_entry_repository = ledger_entry_repository
      @account_repository = account_repository
    end

    def call(institution_id:, period_start:, period_end:, campaign_id: nil)
      entries = @ledger_entry_repository.list_in_period(
        institution_id,
        from: period_start,
        to: period_end,
        campaign_id: campaign_id
      )
      accounts = @account_repository
        .find_by_ids(institution_id: institution_id, ids: entries.map(&:account_id).uniq)
        .index_by(&:id)

      entries.map do |entry|
        account = accounts[entry.account_id]
        if account.nil?
          raise InvalidAccountabilityReport,
            "account #{entry.account_id} not found for ledger entry #{entry.id}"
        end

        AccountabilityReportEntry.from_ledger_entry(entry: entry, account: account)
      end
    end
  end
end
