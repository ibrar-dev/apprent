defmodule AppCount.Repo.Migrations.RestructureAccountingSection do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :payee_id, references(:accounting__payees, on_delete: :delete_all), null: false
    end

    alter table(:accounting__entities) do
      remove :name
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :bank_account_id, references(:accounting__bank_accounts, on_delete: :delete_all), null: false
    end

    alter table(:accounting__invoices) do
      remove :type_id
      remove :class_id
    end

    alter table(:accounting__bank_accounts) do
      remove :class_id
      remove :entity_id
      add :type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false
    end

    alter table(:accounting__charge_types) do
      remove :account_id
      remove :default_cost
      add :type, :string, null: false, default: "income"
    end

    alter table(:accounting__invoicings) do
      remove :entity_id
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false
    end

    drop table(:accounting__groupings)
    drop table(:accounting__classes)
    drop table(:accounting__accounts)

    create unique_index(:accounting__entities, [:property_id, :bank_account_id])
    create unique_index(:accounting__invoicings, [:property_id, :invoice_id])
    create index(:accounting__checks, [:payee_id])
    create index(:accounting__bank_accounts, [:type_id])
    create index(:accounting__invoicings, [:type_id])
  end
end
