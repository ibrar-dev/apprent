defmodule AppCount.Repo.Migrations.CreateAccountingEntities do
  use Ecto.Migration

  def change do
    create table(:accounting__entities) do
      add :name, :string, null: false
      timestamps()
    end

    create unique_index(:accounting__entities, [:name])

    alter table(:accounting__invoicings) do
      remove :property_id
      add :entity_id, references(:accounting__entities, on_delete: :delete_all), null: false
    end

    alter table(:accounting__bank_accounts) do
      remove :property_id
      add :entity_id, references(:accounting__entities, on_delete: :delete_all), null: false
      add :bank_name, :string, null: false
      add :address, :jsonb, default: "{}", null: false
    end

    alter table(:accounting__checks) do
      remove :invoicing_id
    end

    create unique_index(:accounting__invoicings, [:invoice_id, :entity_id])
    create index(:accounting__bank_accounts, [:entity_id])
  end
end
