class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :role, null: false, default: "donor"

      t.timestamps
    end

    add_index :users, "LOWER(email)", unique: true, name: "idx_users_email"
    add_index :users, :role

    add_check_constraint :users,
      "role IN ('donor', 'institution_admin', 'platform_admin')",
      name: "users_role_check"
  end
end
