defmodule AppCount.Admins.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__devices" do
    field :name, :string
    field :private_cert, :string
    field :public_cert, :string
    has_many :device_auths, Module.concat(["AppCount.Admins.DeviceAuth"])

    many_to_many :properties,
                 Module.concat(["AppCount.Properties.Property"]),
                 join_through: Module.concat(["AppCount.Admins.DeviceAuth"])

    timestamps()
  end

  @doc false
  def changeset(devices, attrs) do
    devices
    |> cast(attrs, [:name, :public_cert, :private_cert])
    |> validate_required([:name, :public_cert, :private_cert])
    |> unique_constraint(:name, name: :admins_devices_name_index)
  end
end
