class CreateInstitutions < ActiveRecord::Migration[8.1]
  def change
    create_table :institutions do |t|
      t.references :user, null: false, foreign_key: true

      t.string :legal_name, null: false
      t.string :trade_name

      t.string :settlement_strategy, null: false

      t.string :cnpj
      t.string :legal_entity_kind
      t.decimal :declared_monthly_revenue, precision: 15, scale: 2
      t.string :contact_email
      t.string :mobile_phone

      t.string :address_street
      t.string :address_number
      t.string :address_complement
      t.string :address_neighborhood
      t.string :address_postal_code
      t.string :address_city

      t.string :pix_key

      t.string :asaas_account_id
      t.string :asaas_wallet_id
      t.string :registration_status, null: false, default: "unregistered"
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    # t.references já cria o índice em user_id.
    add_index :institutions, :asaas_wallet_id
    add_index :institutions, :settlement_strategy
    add_index :institutions, :status
    add_index :institutions, :cnpj, unique: true

    add_check_constraint :institutions,
      "settlement_strategy IN ('subaccount', 'pix_payout')",
      name: "institutions_strategy_check"

    add_check_constraint :institutions,
      "registration_status IN ('unregistered', 'pending', 'approved', 'rejected')",
      name: "institutions_registration_check"

    add_check_constraint :institutions,
      "status IN ('draft', 'pending_approval', 'active', 'blocked')",
      name: "institutions_status_check"

    # Uma instituição só pode estar ativa se o caminho de liquidação tiver
    # o que o provedor exige. A versão completa dessas regras mora no domínio;
    # aqui ficam só as impossibilidades estruturais.
    add_check_constraint :institutions,
      "settlement_strategy <> 'subaccount' OR cnpj IS NOT NULL",
      name: "institutions_subaccount_needs_cnpj"

    add_check_constraint :institutions,
      "settlement_strategy <> 'subaccount' OR declared_monthly_revenue IS NOT NULL",
      name: "institutions_subaccount_needs_revenue"

    add_check_constraint :institutions,
      "settlement_strategy <> 'pix_payout' OR pix_key IS NOT NULL",
      name: "institutions_pix_payout_needs_key"
  end
end
