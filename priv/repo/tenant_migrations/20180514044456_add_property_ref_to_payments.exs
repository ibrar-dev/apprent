defmodule AppCount.Repo.Migrations.AddPropertyRefToPayments do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      add :property_id, references(:properties__properties, on_delete: :delete_all)
    end
  end
end
