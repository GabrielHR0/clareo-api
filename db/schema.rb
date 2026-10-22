# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_01_000013) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "institution_id", null: false
    t.string "name", null: false
    t.string "nature", null: false
    t.string "parent_code"
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "code"], name: "index_accounts_on_institution_id_and_code", unique: true
    t.index ["institution_id", "nature"], name: "index_accounts_on_institution_id_and_nature"
    t.index ["institution_id", "parent_code"], name: "index_accounts_on_institution_id_and_parent_code"
    t.check_constraint "nature::text = ANY (ARRAY['income'::character varying, 'expense'::character varying]::text[])", name: "accounts_nature_check"
    t.check_constraint "parent_code IS NULL OR parent_code::text <> code::text", name: "accounts_not_own_parent_check"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.bigint "entity_id"
    t.string "entity_type", null: false
    t.string "ip_address", limit: 45
    t.jsonb "metadata"
    t.bigint "user_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["entity_type", "entity_id"], name: "idx_audit_logs_entity"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.date "ends_on", null: false
    t.decimal "goal_brl", precision: 15, scale: 2, null: false
    t.bigint "institution_id", null: false
    t.date "starts_on", null: false
    t.string "status", default: "active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "ends_on"], name: "index_campaigns_on_institution_id_and_ends_on"
    t.index ["institution_id", "status"], name: "index_campaigns_on_institution_id_and_status"
    t.check_constraint "ends_on >= starts_on", name: "campaigns_period_check"
    t.check_constraint "goal_brl > 0::numeric", name: "campaigns_goal_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'paused'::character varying, 'closed'::character varying]::text[])", name: "campaigns_status_check"
  end

  create_table "cost_centers", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "institution_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "active"], name: "index_cost_centers_on_institution_id_and_active"
    t.index ["institution_id", "code"], name: "index_cost_centers_on_institution_id_and_code", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "institution_id", null: false
    t.date "issued_on"
    t.string "kind", null: false
    t.string "kind_detail"
    t.bigint "ledger_entry_id"
    t.string "number"
    t.bigint "post_id"
    t.datetime "updated_at", null: false
    t.index ["institution_id", "issued_on"], name: "index_documents_on_institution_id_and_issued_on"
    t.index ["institution_id", "kind"], name: "index_documents_on_institution_id_and_kind"
    t.index ["ledger_entry_id"], name: "index_documents_on_ledger_entry_id"
    t.index ["post_id"], name: "index_documents_on_post_id"
    t.check_constraint "kind::text = 'outro'::text AND kind_detail IS NOT NULL AND length(btrim(kind_detail::text)) > 0 OR kind::text <> 'outro'::text AND kind_detail IS NULL", name: "documents_kind_detail_check"
    t.check_constraint "kind::text = ANY (ARRAY['nota_fiscal'::character varying, 'recibo'::character varying, 'contrato'::character varying, 'extrato'::character varying, 'comprovante_pix'::character varying, 'relatorio'::character varying, 'declaracao'::character varying, 'foto'::character varying, 'outro'::character varying]::text[])", name: "documents_kind_check"
    t.check_constraint "ledger_entry_id IS NOT NULL AND post_id IS NULL OR ledger_entry_id IS NULL AND post_id IS NOT NULL", name: "documents_exactly_one_attachable_check"
  end

  create_table "donation_splits", force: :cascade do |t|
    t.string "asaas_split_id"
    t.string "cancellation_reason"
    t.datetime "created_at", null: false
    t.bigint "donation_id", null: false
    t.bigint "institution_id"
    t.decimal "percentage", precision: 7, scale: 4, null: false
    t.string "recipient", null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_value_brl", precision: 15, scale: 2
    t.datetime "updated_at", null: false
    t.index ["donation_id"], name: "index_donation_splits_on_donation_id"
    t.index ["institution_id"], name: "index_donation_splits_on_institution_id"
    t.index ["status"], name: "index_donation_splits_on_status"
    t.check_constraint "percentage > 0::numeric AND percentage <= 100::numeric", name: "donation_splits_percentage_check"
    t.check_constraint "recipient::text = 'institution'::text AND institution_id IS NOT NULL OR recipient::text = 'platform'::text AND institution_id IS NULL", name: "donation_splits_recipient_institution"
    t.check_constraint "recipient::text = ANY (ARRAY['institution'::character varying::text, 'platform'::character varying::text])", name: "donation_splits_recipient_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'done'::character varying::text, 'cancelled'::character varying::text, 'blocked'::character varying::text])", name: "donation_splits_status_check"
  end

  create_table "donations", force: :cascade do |t|
    t.decimal "amount_brl", precision: 15, scale: 2, null: false
    t.string "asaas_customer_id"
    t.string "asaas_payment_id"
    t.bigint "campaign_id"
    t.datetime "created_at", null: false
    t.string "donor_email"
    t.string "donor_name", null: false
    t.bigint "institution_id", null: false
    t.decimal "net_amount_brl", precision: 15, scale: 2
    t.string "payment_method", null: false
    t.datetime "received_at"
    t.string "reference", null: false
    t.datetime "refunded_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["asaas_payment_id"], name: "index_donations_on_asaas_payment_id"
    t.index ["campaign_id"], name: "index_donations_on_campaign_id"
    t.index ["created_at"], name: "index_donations_on_created_at"
    t.index ["donor_email"], name: "index_donations_on_donor_email"
    t.index ["institution_id"], name: "index_donations_on_institution_id"
    t.index ["reference"], name: "index_donations_on_reference", unique: true
    t.index ["status"], name: "index_donations_on_status"
    t.check_constraint "amount_brl > 0::numeric", name: "donations_amount_positive"
    t.check_constraint "net_amount_brl IS NULL OR net_amount_brl >= 0::numeric", name: "donations_net_amount_check"
    t.check_constraint "payment_method::text = ANY (ARRAY['pix'::character varying::text, 'boleto'::character varying::text, 'credit_card'::character varying::text])", name: "donations_payment_method_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'received'::character varying::text, 'refunded'::character varying::text, 'cancelled'::character varying::text, 'rejected'::character varying::text, 'split_blocked'::character varying::text])", name: "donations_status_check"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "address_city"
    t.string "address_complement"
    t.string "address_neighborhood"
    t.string "address_number"
    t.string "address_postal_code"
    t.string "address_street"
    t.string "asaas_account_id"
    t.string "asaas_wallet_id"
    t.string "cnpj"
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.decimal "declared_monthly_revenue", precision: 15, scale: 2
    t.string "legal_entity_kind"
    t.string "legal_name", null: false
    t.string "mobile_phone"
    t.string "pix_key"
    t.string "registration_status", default: "unregistered", null: false
    t.string "settlement_strategy", null: false
    t.string "status", default: "draft", null: false
    t.string "trade_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["asaas_wallet_id"], name: "index_institutions_on_asaas_wallet_id"
    t.index ["cnpj"], name: "index_institutions_on_cnpj", unique: true
    t.index ["settlement_strategy"], name: "index_institutions_on_settlement_strategy"
    t.index ["status"], name: "index_institutions_on_status"
    t.index ["user_id"], name: "index_institutions_on_user_id"
    t.check_constraint "registration_status::text = ANY (ARRAY['unregistered'::character varying::text, 'pending'::character varying::text, 'approved'::character varying::text, 'rejected'::character varying::text])", name: "institutions_registration_check"
    t.check_constraint "settlement_strategy::text <> 'pix_payout'::text OR pix_key IS NOT NULL", name: "institutions_pix_payout_needs_key"
    t.check_constraint "settlement_strategy::text <> 'subaccount'::text OR cnpj IS NOT NULL", name: "institutions_subaccount_needs_cnpj"
    t.check_constraint "settlement_strategy::text <> 'subaccount'::text OR declared_monthly_revenue IS NOT NULL", name: "institutions_subaccount_needs_revenue"
    t.check_constraint "settlement_strategy::text = ANY (ARRAY['subaccount'::character varying::text, 'pix_payout'::character varying::text])", name: "institutions_strategy_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying::text, 'pending_approval'::character varying::text, 'active'::character varying::text, 'blocked'::character varying::text])", name: "institutions_status_check"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.decimal "amount_brl", precision: 15, scale: 2, null: false
    t.bigint "campaign_id"
    t.bigint "cost_center_id"
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "donation_split_id"
    t.bigint "institution_id", null: false
    t.string "kind", null: false
    t.string "origin", null: false
    t.date "posted_on"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.string "void_reason"
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["campaign_id"], name: "index_ledger_entries_on_campaign_id"
    t.index ["cost_center_id"], name: "index_ledger_entries_on_cost_center_id"
    t.index ["donation_split_id"], name: "idx_ledger_entries_one_per_donation_split", unique: true, where: "((origin)::text = 'donation'::text)"
    t.index ["institution_id", "kind"], name: "index_ledger_entries_on_institution_id_and_kind"
    t.index ["institution_id", "posted_on"], name: "index_ledger_entries_on_institution_id_and_posted_on"
    t.index ["institution_id", "status"], name: "index_ledger_entries_on_institution_id_and_status"
    t.check_constraint "amount_brl >= 0::numeric", name: "ledger_entries_amount_check"
    t.check_constraint "kind::text = ANY (ARRAY['income'::character varying, 'expense'::character varying]::text[])", name: "ledger_entries_kind_check"
    t.check_constraint "origin::text <> 'declared'::text OR donation_split_id IS NULL", name: "ledger_entries_declared_without_split_check"
    t.check_constraint "origin::text <> 'donation'::text OR kind::text = 'income'::text AND donation_split_id IS NOT NULL AND status::text = 'posted'::text", name: "ledger_entries_donation_shape_check"
    t.check_constraint "origin::text <> 'donation'::text OR void_reason IS NULL", name: "ledger_entries_donation_not_voided_check"
    t.check_constraint "origin::text = ANY (ARRAY['donation'::character varying, 'declared'::character varying]::text[])", name: "ledger_entries_origin_check"
    t.check_constraint "status::text <> 'voided'::text OR void_reason IS NOT NULL AND length(btrim(void_reason::text)) > 0", name: "ledger_entries_void_reason_check"
    t.check_constraint "status::text = ANY (ARRAY['draft'::character varying, 'posted'::character varying, 'voided'::character varying]::text[])", name: "ledger_entries_status_check"
  end

  create_table "payouts", force: :cascade do |t|
    t.decimal "amount_brl", precision: 15, scale: 2, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "donation_id"
    t.text "failure_reason"
    t.bigint "institution_id", null: false
    t.string "pix_key", null: false
    t.string "provider_transfer_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["donation_id", "institution_id"], name: "idx_payouts_one_per_donation", unique: true, where: "(donation_id IS NOT NULL)"
    t.index ["donation_id"], name: "index_payouts_on_donation_id"
    t.index ["institution_id"], name: "index_payouts_on_institution_id"
    t.index ["provider_transfer_id"], name: "index_payouts_on_provider_transfer_id"
    t.index ["status"], name: "index_payouts_on_status"
    t.check_constraint "amount_brl > 0::numeric", name: "payouts_amount_positive"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text, 'cancelled'::character varying::text])", name: "payouts_status_check"
  end

  create_table "plans", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.jsonb "features", default: [], null: false
    t.string "name", null: false
    t.decimal "price_brl", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_plans_on_code", unique: true
    t.check_constraint "code::text = ANY (ARRAY['free'::character varying::text, 'pro'::character varying::text, 'enterprise'::character varying::text])", name: "plans_code_check"
    t.check_constraint "price_brl >= 0::numeric", name: "plans_price_check"
  end

  create_table "posts", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "institution_id", null: false
    t.string "post_type", default: "update", null: false
    t.datetime "published_at"
    t.string "status", default: "published", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id", "post_type"], name: "index_posts_on_institution_id_and_post_type"
    t.index ["institution_id", "published_at"], name: "index_posts_on_institution_id_and_published_at"
    t.index ["institution_id", "status"], name: "index_posts_on_institution_id_and_status"
    t.check_constraint "post_type::text = ANY (ARRAY['update'::character varying, 'report'::character varying]::text[])", name: "posts_post_type_check"
    t.check_constraint "status::text = ANY (ARRAY['published'::character varying, 'hidden'::character varying]::text[])", name: "posts_status_check"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "asaas_subscription_id"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_ends_at"
    t.bigint "institution_id", null: false
    t.bigint "plan_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["asaas_subscription_id"], name: "index_subscriptions_on_asaas_subscription_id"
    t.index ["institution_id"], name: "idx_subscriptions_one_active_per_institution", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["institution_id"], name: "index_subscriptions_on_institution_id"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'past_due'::character varying::text, 'cancelled'::character varying::text, 'expired'::character varying::text])", name: "subscriptions_status_check"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "role", default: "donor", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "idx_users_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.check_constraint "role::text = ANY (ARRAY['donor'::character varying::text, 'institution_admin'::character varying::text, 'platform_admin'::character varying::text])", name: "users_role_check"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.string "event", null: false
    t.jsonb "payload", null: false
    t.datetime "processed_at"
    t.string "provider", default: "asaas", null: false
    t.string "provider_event_id", limit: 128, null: false
    t.string "resource_id"
    t.string "resource_type"
    t.string "status", default: "received", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_events_on_created_at"
    t.index ["provider_event_id"], name: "index_webhook_events_on_provider_event_id", unique: true
    t.index ["resource_type", "resource_id"], name: "idx_webhook_events_resource"
    t.index ["status"], name: "index_webhook_events_on_status"
    t.check_constraint "status::text = ANY (ARRAY['received'::character varying::text, 'processing'::character varying::text, 'processed'::character varying::text, 'failed'::character varying::text])", name: "webhook_events_status_check"
  end

  add_foreign_key "accounts", "institutions"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "campaigns", "institutions"
  add_foreign_key "cost_centers", "institutions"
  add_foreign_key "documents", "institutions"
  add_foreign_key "documents", "ledger_entries"
  add_foreign_key "documents", "posts"
  add_foreign_key "donation_splits", "donations"
  add_foreign_key "donation_splits", "institutions"
  add_foreign_key "donations", "campaigns"
  add_foreign_key "donations", "institutions"
  add_foreign_key "institutions", "users"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "campaigns"
  add_foreign_key "ledger_entries", "donation_splits"
  add_foreign_key "ledger_entries", "institutions"
  add_foreign_key "payouts", "donations"
  add_foreign_key "payouts", "institutions"
  add_foreign_key "posts", "institutions"
  add_foreign_key "subscriptions", "institutions"
  add_foreign_key "subscriptions", "plans"
end
