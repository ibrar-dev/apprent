defmodule AppCount.Repo.Migrations.RenameChargeTypes do
  use Ecto.Migration

  def change do
    drop index(:accounting__bank_accounts, [:type_id])
    drop index(:accounting__charges, [:type_id])
    drop index(:accounting__invoicings, [:type_id])
    drop index(:properties__charges, [:type_id])
    drop index(:accounting__charge_types, [:name])

    rename table(:accounting__charge_types), to: table(:accounting__accounts)
    rename table(:accounting__bank_accounts), :type_id, to: :account_id
    rename table(:accounting__charges), :type_id, to: :account_id
    rename table(:accounting__invoicings), :type_id, to: :account_id
    rename table(:properties__charges), :type_id, to: :account_id

    alter table(:accounting__invoices) do
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false
    end

    create index(:accounting__bank_accounts, [:account_id])
    create index(:accounting__charges, [:account_id])
    create index(:accounting__invoicings, [:account_id])
    create index(:properties__charges, [:account_id])
    create index(:accounting__invoices, [:account_id])
    create unique_index(:accounting__accounts, [:name])
  end
end
