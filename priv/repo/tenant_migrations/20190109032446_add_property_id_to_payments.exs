defmodule AppCount.Repo.Migrations.AddPropertyIdToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      remove :charge_id
      add :property_id, references(:properties__properties, on_delete: :delete_all)
    end
  end
end
