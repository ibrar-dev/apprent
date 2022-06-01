defmodule AppCount.Repo.Migrations.AddOrderIdToPersons do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__persons) do
      add :order_id, :string
    end
  end
end
