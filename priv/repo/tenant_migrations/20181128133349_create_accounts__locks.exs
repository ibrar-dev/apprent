defmodule AppCount.Repo.Migrations.CreateAccountsLocks do
  use Ecto.Migration

  def change do
    create table(:accounts__locks) do
      add :reason, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :comments, :text
      add :account_id, references(:accounts__accounts, on_delete: :delete_all), null: false
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)

      timestamps()
    end

    create index(:accounts__locks, [:account_id])
    create index(:accounts__locks, [:admin_id])
  end
end
