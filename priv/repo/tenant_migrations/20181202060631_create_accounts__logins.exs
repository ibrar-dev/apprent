defmodule AppCount.Repo.Migrations.CreateAccountsLogins do
  use Ecto.Migration

  def change do
    create table(:accounts__logins) do
      add :type, :string, null: false
      add :account_id, references(:accounts__accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:accounts__logins, [:account_id])
  end
end
