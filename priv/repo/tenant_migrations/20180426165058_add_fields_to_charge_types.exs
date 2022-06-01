defmodule AppCount.Repo.Migrations.AddFieldsToChargeTypes do
  use Ecto.Migration

  def change do
    alter table(:accounting__charge_types) do
      remove :code
      add :property_id, references(:properties__properties, on_delete: :delete_all), null: false
      add :default_cost, :decimal
    end
  end
end
