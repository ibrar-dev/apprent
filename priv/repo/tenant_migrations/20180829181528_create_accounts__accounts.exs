defmodule AppCount.Repo.Migrations.CreateAccountsAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts__accounts) do
      add :encrypted_password, :string, null: false
      add :password_changed, :boolean, default: false, null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounts__accounts, [:tenant_id])
  end
end
