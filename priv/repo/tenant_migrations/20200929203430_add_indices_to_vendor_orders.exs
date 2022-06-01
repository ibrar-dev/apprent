defmodule AppCount.Repo.Migrations.AddIndicesToVendorOrders do
  use Ecto.Migration

  def change do
    create index("vendors__orders", [:admin_id])
    create index("vendors__orders", [:vendor_id])
    create index("vendors__orders", [:category_id])
    create index("vendors__orders", [:unit_id])
    create index("vendors__orders", [:tenant_id])
    create index("vendors__orders", [:card_item_id])
  end
end
