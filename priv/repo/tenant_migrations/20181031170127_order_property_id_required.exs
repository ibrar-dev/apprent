defmodule AppCount.Repo.Migrations.OrderPropertyIdRequired do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      modify :property_id, :bigint, null: false
    end
  end
end
