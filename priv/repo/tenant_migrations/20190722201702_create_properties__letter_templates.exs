defmodule AppCount.Repo.Migrations.CreatePropertiesLetterTemplates do
  use Ecto.Migration

  def change do
    create table(:properties__letter_templates) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :body, :text, null: false
      timestamps()
    end

    create index(:properties__letter_templates, [:property_id])
  end
end
