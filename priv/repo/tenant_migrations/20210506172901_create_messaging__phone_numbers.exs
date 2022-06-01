defmodule AppCount.Repo.Migrations.CreateMessagingPhoneNumbers do
  use Ecto.Migration

  def change do
    create table(:messaging__phone_numbers) do
      add :number, :string, null: false
      add :context, :string, null: false, default: "all"
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:messaging__phone_numbers, [:number])
    create index(:messaging__phone_numbers, [:property_id])
  end
end
