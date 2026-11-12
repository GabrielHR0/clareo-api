require_relative "../../domain_helper"

RSpec.describe AccountabilityReport do
  let(:institution_id) { "ins_1" }
  let(:period_start) { Date.new(2026, 1, 1) }
  let(:period_end) { Date.new(2026, 1, 31) }
  let(:submitted_at) { Time.utc(2026, 2, 1, 10, 0, 0) }

  def report(**overrides)
    described_class.build(
      institution_id: institution_id,
      title: "Prestação de contas de janeiro",
      summary: "Recursos recebidos e aplicados no período.",
      period_start: period_start,
      period_end: period_end,
      **overrides
    )
  end

  def entry(**overrides)
    AccountabilityReportEntry.build(
      institution_id: institution_id,
      ledger_entry_id: 1,
      account_id: 11,
      account_code: "1.1",
      account_name: "Receitas de Doações",
      kind: :income,
      origin: :donation,
      posted_on: Date.new(2026, 1, 15),
      amount: "100.00",
      **overrides
    )
  end

  def submitted(**overrides)
    report.submit!(entries: [ entry ], at: submitted_at)
  end

  describe "submission" do
    it "starts as a draft and editable" do
      expect(report).to be_draft
      expect(report).to be_editable
      expect(report).not_to be_public
    end

    it "freezes the entries and moves to submitted" do
      result = submitted

      expect(result).to be_submitted
      expect(result.submitted_at).to eq(submitted_at)
      expect(result.entries.size).to eq(1)
      expect(result).not_to be_editable
    end

    it "requires a summary before submission" do
      expect { report(summary: nil).submit!(entries: [ entry ], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /summary is required/)
    end

    it "requires at least one entry" do
      expect { report.submit!(entries: [], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /at least one entry/)
    end

    it "refuses duplicate ledger entries, because the same number cannot count twice" do
      duplicated = entry

      expect { report.submit!(entries: [ duplicated, duplicated ], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /cannot appear twice/)
    end

    it "refuses an entry from another tenant" do
      expect { report.submit!(entries: [ entry(institution_id: "ins_2") ], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /another institution/)
    end

    it "refuses an entry outside the period" do
      expect { report.submit!(entries: [ entry(posted_on: Date.new(2026, 2, 1)) ], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /outside the report period/)
    end

    it "refuses an entry from another campaign when the report is campaign scoped" do
      scoped = report(campaign_id: 7)

      expect { scoped.submit!(entries: [ entry(campaign_id: 8) ], at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /another campaign/)
    end

    it "accepts entries from any campaign when the report is institution wide" do
      result = report.submit!(
        entries: [ entry(campaign_id: 7), entry(ledger_entry_id: 2, campaign_id: 8) ],
        at: submitted_at
      )

      expect(result.entries.size).to eq(2)
    end

    it "clears the previous review when the institution resubmits" do
      changes = submitted.start_review!(reviewer_id: 9, at: submitted_at)
        .request_changes!(reviewer_id: 9, notes: "Falta comprovante", at: submitted_at)

      resubmitted = changes.submit!(entries: [ entry ], at: submitted_at + 86_400)

      expect(resubmitted.review_notes).to be_nil
      expect(resubmitted.reviewer_id).to be_nil
      expect(resubmitted.approved_at).to be_nil
    end
  end

  describe "editing" do
    it "allows a draft to change its details" do
      updated = report.update_details!(
        title: "Novo título",
        summary: "Novo resumo",
        period_start: Date.new(2026, 2, 1),
        period_end: Date.new(2026, 2, 28),
        campaign_id: 7
      )

      expect(updated.title).to eq("Novo título")
      expect(updated.campaign_id).to eq(7)
    end

    it "refuses edits after submission" do
      expect {
        submitted.update_details!(
          title: "Outro", summary: "Outro",
          period_start: period_start, period_end: period_end
        )
      }.to raise_error(InvalidAccountabilityReport, /cannot edit/)
    end

    it "refuses a period end before the start" do
      expect {
        report.update_details!(
          title: "Inválido", summary: "Inválido",
          period_start: Date.new(2026, 2, 1), period_end: Date.new(2026, 1, 1)
        )
      }.to raise_error(InvalidAccountabilityReport, /period end/)
    end
  end

  describe "review" do
    it "walks submitted -> under_review -> approved -> published" do
      result = submitted
        .start_review!(reviewer_id: 9, at: submitted_at)
        .approve!(reviewer_id: 9, opinion: "Documentação conferida", at: submitted_at)
        .publish!(at: submitted_at + 60)

      expect(result).to be_published
      expect(result.review_opinion).to eq("Documentação conferida")
      expect(result.approved_at).not_to be_nil
      expect(result.published_at).not_to be_nil
    end

    it "can request changes and return to the institution" do
      result = submitted
        .start_review!(reviewer_id: 9, at: submitted_at)
        .request_changes!(reviewer_id: 9, notes: "Falta nota fiscal", at: submitted_at)

      expect(result).to be_changes_requested
      expect(result.review_notes).to eq("Falta nota fiscal")
      expect(result).to be_editable
    end

    it "requires the platform review before approval" do
      expect {
        submitted.approve!(reviewer_id: 9, opinion: "Ok", at: submitted_at)
      }.to raise_error(InvalidAccountabilityReport, /cannot move report/)
    end

    it "requires an opinion to approve" do
      under_review = submitted.start_review!(reviewer_id: 9, at: submitted_at)

      expect {
        under_review.approve!(reviewer_id: 9, opinion: " ", at: submitted_at)
      }.to raise_error(InvalidAccountabilityReport, /review opinion/)
    end

    it "requires notes to request changes" do
      under_review = submitted.start_review!(reviewer_id: 9, at: submitted_at)

      expect {
        under_review.request_changes!(reviewer_id: 9, notes: "", at: submitted_at)
      }.to raise_error(InvalidAccountabilityReport, /review notes/)
    end

    it "requires approval before publishing" do
      expect { submitted.publish!(at: submitted_at) }
        .to raise_error(InvalidAccountabilityReport, /cannot move report/)
    end

    it "refuses to edit or resubmit a published report" do
      published = submitted
        .start_review!(reviewer_id: 9, at: submitted_at)
        .approve!(reviewer_id: 9, opinion: "Ok", at: submitted_at)
        .publish!(at: submitted_at)

      expect {
        published.submit!(entries: [ entry ], at: submitted_at)
      }.to raise_error(InvalidAccountabilityReport, /cannot edit/)
    end
  end

  describe "totals" do
    it "sums income and expenses from the frozen entries" do
      result = report.submit!(
        entries: [
          entry(amount: "100.00"),
          entry(ledger_entry_id: 2, kind: :expense, origin: :declared, amount: "40.00"),
          entry(ledger_entry_id: 3, kind: :income, origin: :declared, amount: "10.00")
        ],
        at: submitted_at
      )

      expect(result.total_income).to eq(Money.brl("110.00"))
      expect(result.total_expense).to eq(Money.brl("40.00"))
      expect(result.balance).to eq(Money.brl("70.00"))
    end
  end
end
