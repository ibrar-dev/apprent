defmodule AppCount.Vendors.Property do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Vendors.Property

  schema "vendor__properties" do
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :vendor, Module.concat(["AppCount.Vendors.Vendor"])

    timestamps()
  end

  @doc false
  def changeset(%Property{} = property, attrs) do
    property
    |> cast(attrs, [:vendor_id, :property_id])
    |> validate_required([:vendor_id, :property_id])
  end
end
