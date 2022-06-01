defmodule AppCount.Repo.Migrations.AddIndicesToVendorProperties do
  use Ecto.Migration

  def change do
    create index("vendor__properties", [:property_id])
    create index("vendor__properties", [:vendor_id])
  end
end
