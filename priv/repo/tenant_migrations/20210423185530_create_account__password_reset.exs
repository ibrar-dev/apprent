defmodule AppCount.Repo.Migrations.CreateAccountPasswordReset do
  use Ecto.Migration

  def change do
    create table(:accounts__password_resets) do
      add :account_id, references(:accounts__accounts, on_delete: :delete_all), null: false
      add :admin_id, references(:admins__admins, on_delete: :nilify_all)

      timestamps()
    end

    create index(:accounts__password_resets, [:account_id])
    create index(:accounts__password_resets, [:admin_id])
  end
end
