class AddPublicProfileToInstitutions < ActiveRecord::Migration[8.1]
  def up
    add_column :institutions, :description, :text
    add_column :institutions, :slug, :string

    # Instituições que já existem recebem um slug estável. O nome pode ter
    # acento e espaço; o id garante unicidade sem inventar transliteração no SQL.
    execute <<~SQL
      UPDATE institutions
         SET slug = 'instituicao-' || id
       WHERE slug IS NULL
    SQL

    add_index :institutions, "lower(slug)",
      unique: true,
      where: "slug IS NOT NULL",
      name: "idx_institutions_slug"

    add_check_constraint :institutions,
      "slug IS NULL OR slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'",
      name: "institutions_slug_format_check"
  end

  def down
    remove_check_constraint :institutions, name: "institutions_slug_format_check"
    remove_index :institutions, name: "idx_institutions_slug"
    remove_column :institutions, :slug
    remove_column :institutions, :description
  end
end
