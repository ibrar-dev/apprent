defmodule AppCount.Admins.DeviceAuth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__device_auths" do
    belongs_to :device, Module.concat(["AppCount.Admins.Device"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(device_auth, attrs) do
    device_auth
    |> cast(attrs, [:device_id, :property_id])
    |> validate_required([:device_id, :property_id])
    |> unique_constraint(:unique, name: :admins__device_auths_device_id_property_id_index)
  end
end
