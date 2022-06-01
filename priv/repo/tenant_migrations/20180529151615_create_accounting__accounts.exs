defmodule AppCount.Repo.Migrations.CreateAccountingAccounts do
  use Ecto.Migration

  def change do
    create table(:accounting__accounts) do
      add :name, :string, null: false

      timestamps()
    end

    alter table(:accounting__charges) do
      add :account_id, references(:accounting__accounts, on_delete: :nilify_all)
    end

    alter table(:properties__charges) do
      add :account_id, references(:accounting__accounts, on_delete: :nilify_all)
      add :type_id, references(:accounting__charge_types, on_delete: :delete_all)
    end

    create index(:accounting__charges, [:account_id])
    create index(:properties__charges, [:account_id])
    create index(:properties__charges, [:type_id])
  end
end
