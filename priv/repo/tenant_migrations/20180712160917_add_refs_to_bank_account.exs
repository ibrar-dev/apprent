defmodule AppCount.Repo.Migrations.AddRefsToBankAccount do
  use Ecto.Migration

  def change do
    alter table(:accounting__bank_accounts) do
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
    end

    alter table(:accounting__invoices) do
      add :number, :string, null: false
      remove :account_id
      add :type_id, references(:accounting__charge_types, on_delete: :delete_all), null: false
      add :due_date, :date, null: false
      add :notes, :text
    end

    create unique_index(:accounting__invoices, [:number, :payee_id])
    create index(:accounting__invoices, [:type_id])
  end
end
