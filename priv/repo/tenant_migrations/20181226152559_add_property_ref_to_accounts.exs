defmodule AppCount.Repo.Migrations.AddPropertyRefToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts__accounts) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :username, :string, null: false
    end

    create unique_index(:accounts__accounts, [:username])
    create unique_index(:accounts__accounts, [:tenant_id, :property_id])
  end
end
