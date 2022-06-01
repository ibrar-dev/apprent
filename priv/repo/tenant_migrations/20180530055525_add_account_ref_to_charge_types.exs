defmodule AppCount.Repo.Migrations.AddAccountRefToChargeTypes do
  use Ecto.Migration

  def change do
    alter table(:accounting__charge_types) do
      add :account_id, references(:accounting__accounts, on_delete: :delete_all), null: false
      remove :property_id
    end

    create index(:accounting__charge_types, [:account_id])
  end
end
