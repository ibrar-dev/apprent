defmodule AppCount.Vendors.Note do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :text,
             :image,
             :admin_id,
             :order_id,
             :vendor_id,
             :tech_id
           ]}

  schema "vendors__notes" do
    field :text, :string
    field :image, :string
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])
    belongs_to :tenant, Module.concat(["AppCount.Tenants.Tenant"])
    belongs_to :order, Module.concat(["AppCount.Vendors.Order"])
    belongs_to :vendor, Module.concat(["AppCount.Vendors.Vendor"])
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:text, :order_id, :tenant_id, :admin_id, :vendor_id, :tech_id, :inserted_at])
    |> validate_required([:text, :order_id])
  end

  def image_url(%{image: img} = note) when is_binary(img) do
    env = AppCount.env()[:environment]

    "https://s3-us-east-2.amazonaws.com/appcount-maintenance/vendor_notes/#{env}/#{note.id}/#{img}"
  end

  def image_url(_), do: nil
end
