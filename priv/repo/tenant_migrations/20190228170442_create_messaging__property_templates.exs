defmodule AppCount.Repo.Migrations.CreateMessagingPropertyTemplates do
  use Ecto.Migration

  def change do
    create table(:messaging__property_templates) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :template_id, references(:messaging__mail_templates, on_delete: :delete_all), null: false
      timestamps()
    end
    create unique_index(:messaging__property_templates, [:property_id, :template_id])
  end
end
