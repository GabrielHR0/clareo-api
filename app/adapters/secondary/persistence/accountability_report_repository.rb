module Persistence
  # Implementa Repositories::AccountabilityReportRepository.
  class AccountabilityReportRepository
    def find(id)
      record = AccountabilityReportRecord.includes(:entry_records).find_by(id: id)
      record && RecordMapper.record_to_accountability_report(record)
    end

    def find_for_institution(id:, institution_id:)
      record = AccountabilityReportRecord
        .includes(:entry_records)
        .find_by(id: id, institution_id: institution_id)
      record && RecordMapper.record_to_accountability_report(record)
    end

    def find_published(id)
      record = AccountabilityReportRecord
        .published
        .includes(:entry_records)
        .find_by(id: id)
      record && RecordMapper.record_to_accountability_report(record)
    end

    def list_by_institution(institution_id, status: nil)
      scope = AccountabilityReportRecord
        .includes(:entry_records)
        .where(institution_id: institution_id)
      scope = scope.where(status: status.to_s) if status
      scope.order(period_end: :desc, id: :desc).map do |record|
        RecordMapper.record_to_accountability_report(record)
      end
    end

    def list_published(institution_id, campaign_id: nil, limit: nil, offset: nil)
      scope = AccountabilityReportRecord
        .published
        .includes(:entry_records)
        .where(institution_id: institution_id)
      scope = scope.where(campaign_id: campaign_id) if campaign_id
      scope = scope.order(published_at: :desc, id: :desc)
      scope = scope.limit(limit) if limit
      scope = scope.offset(offset) if offset
      scope.map { |record| RecordMapper.record_to_accountability_report(record) }
    end

    def list_pending(limit: nil, offset: nil)
      scope = AccountabilityReportRecord
        .in_review
        .includes(:entry_records)
        .order(submitted_at: :asc, id: :asc)
      scope = scope.limit(limit) if limit
      scope = scope.offset(offset) if offset
      scope.map { |record| RecordMapper.record_to_accountability_report(record) }
    end

    def save(report, sync_entries: false)
      AccountabilityReportRecord.transaction do
        record = record_for(report)
        RecordMapper.accountability_report_to_record(report, record)
        record.save!

        sync_entries!(record, report.entries) if sync_entries

        RecordMapper.record_to_accountability_report(record, entries: report.entries)
      end
    end

    private

      def record_for(report)
        return AccountabilityReportRecord.new if report.id.nil?

        AccountabilityReportRecord.find_by(id: report.id) || AccountabilityReportRecord.new
      end

      def sync_entries!(record, entries)
        record.entry_records.destroy_all

        entries.each do |entry|
          RecordMapper
            .accountability_report_entry_to_record(entry, report_id: record.id)
            .save!
        end
      end
  end
end
