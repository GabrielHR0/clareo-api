class CreateAccountabilityReports < ActiveRecord::Migration[8.1]
  def up
    create_table :accountability_reports do |t|
      t.bigint :institution_id, null: false
      t.bigint :campaign_id
      t.string :title, null: false
      t.text :summary
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :submitted_at
      t.datetime :review_started_at
      t.datetime :approved_at
      t.datetime :published_at
      t.bigint :reviewer_id
      t.text :review_opinion
      t.text :review_notes

      t.timestamps
    end

    # A chave composta permite que as entradas provem, no banco, que o relatório
    # e o lançamento são do mesmo tenant.
    add_index :accountability_reports, [ :id, :institution_id ],
      unique: true,
      name: "idx_accountability_reports_id_institution"

    add_foreign_key :accountability_reports, :institutions
    add_foreign_key :accountability_reports, :users, column: :reviewer_id

    execute <<~SQL
      ALTER TABLE accountability_reports
        ADD CONSTRAINT fk_accountability_reports_campaign_same_institution
        FOREIGN KEY (campaign_id, institution_id)
        REFERENCES campaigns (id, institution_id)
    SQL

    add_index :accountability_reports, [ :institution_id, :status ]
    add_index :accountability_reports, [ :status, :submitted_at ]
    add_index :accountability_reports, [ :campaign_id, :period_end ]
    add_index :accountability_reports, [ :institution_id, :campaign_id, :period_start, :period_end ],
      name: "idx_accountability_reports_period"
    add_index :accountability_reports, :published_at

    add_check_constraint :accountability_reports,
      "status IN ('draft', 'submitted', 'under_review', 'approved', 'changes_requested', 'published')",
      name: "accountability_reports_status_check"

    add_check_constraint :accountability_reports,
      "period_end >= period_start",
      name: "accountability_reports_period_check"

    add_check_constraint :accountability_reports,
      "status <> 'published' OR published_at IS NOT NULL",
      name: "accountability_reports_published_at_check"

    add_check_constraint :accountability_reports,
      "status NOT IN ('approved', 'published') OR approved_at IS NOT NULL",
      name: "accountability_reports_approved_at_check"

    add_check_constraint :accountability_reports,
      "status NOT IN ('submitted', 'under_review', 'approved', 'changes_requested', 'published') OR submitted_at IS NOT NULL",
      name: "accountability_reports_submitted_at_check"

    add_check_constraint :accountability_reports,
      "status <> 'under_review' OR reviewer_id IS NOT NULL",
      name: "accountability_reports_reviewer_check"

    add_check_constraint :accountability_reports,
      "status NOT IN ('approved', 'published') OR review_opinion IS NOT NULL",
      name: "accountability_reports_opinion_check"
  end

  def down
    drop_table :accountability_reports
  end
end
