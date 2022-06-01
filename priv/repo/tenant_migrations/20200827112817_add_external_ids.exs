defmodule AppCount.Repo.Migrations.AddExternalIds do
  use Ecto.Migration

  def change do
    alter table(:properties__properties) do
      add :external_id, :string
    end

    alter table(:tenants__tenants) do
      add :external_id, :string
    end

    alter table(:accounting__accounts) do
      add :external_id, :string
    end

    alter table(:vendors__vendors) do
      add :external_id, :string
    end

    alter table(:rent_apply__persons) do
      add :external_id, :string
    end

    alter table(:properties__units) do
      add :external_id, :string
    end

    alter table(:accounting__invoices) do
      add :external_id, :string
    end

    create unique_index(:properties__properties, [:external_id])
    create unique_index(:tenants__tenants, [:external_id])
    create unique_index(:accounting__accounts, [:external_id])
    create unique_index(:vendors__vendors, [:external_id])
    create unique_index(:rent_apply__persons, [:external_id])
    create unique_index(:properties__units, [:external_id])
    create unique_index(:accounting__invoices, [:external_id])
  end
end
