defmodule AppCount.Repo.Migrations.CreateAuthorizeAccounts do
  use Ecto.Migration

  def change do
    create table(:properties__authorize_accounts) do
      add :api_key, :string, null: false
      add :transaction_key, :string, null: false
      add :public_key, :string, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:properties__authorize_accounts, [:property_id])
    create unique_index(:properties__authorize_accounts, [:api_key])
  end
end
