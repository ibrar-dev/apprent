defmodule AppCount.Repo.Migrations.AddClassRefToBankAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounting__bank_accounts) do
      add :class_id, references(:accounting__classes, on_delete: :delete_all), null: false
    end

    create index(:accounting__bank_accounts, [:class_id])
  end
end
