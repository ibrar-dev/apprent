defmodule AppCount.Repo.Migrations.RemoveOrderIdFromVendor do
  use Ecto.Migration

  def change do
    alter table(:maintenance__orders) do
      remove :vendor_order_id
    end
  end
end
