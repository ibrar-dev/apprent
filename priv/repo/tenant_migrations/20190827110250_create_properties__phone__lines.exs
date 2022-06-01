defmodule AppCount.Repo.Migrations.CreatePropertiesPhoneLines do
  use Ecto.Migration

  def change do
    create table(:properties__phone__lines) do
      add :number, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__phone__lines, [:number])
    create index(:properties__phone__lines, [:property_id])
    create constraint(:properties__phone__lines, :valid_phone_number, check: "number ~* '\\(\\d{3}\\) \\d{3}-\\d{4}'")
  end
end
