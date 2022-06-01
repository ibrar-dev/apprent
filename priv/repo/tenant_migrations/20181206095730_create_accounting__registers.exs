defmodule AppCount.Repo.Migrations.CreateAccountingRegisters do
  use Ecto.Migration

  def change do
    create table(:accounting__registers) do
      add :is_default, :boolean, default: false, null: false
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :cash_account_id, references(:accounting__cash_accounts, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:accounting__registers, [:property_id, :cash_account_id])
    create unique_index(:accounting__registers, [:property_id], where: "is_default = 't'")
  end
end
