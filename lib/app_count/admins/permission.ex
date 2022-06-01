defmodule AppCount.Admins.Permission do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Admins.Permission

  schema "admins__permissions" do
    belongs_to(:admin, Module.concat(["AppCount.Admins.Admin"]))
    belongs_to(:region, Module.concat(["AppCount.Admins.Region"]))

    timestamps()
  end

  @doc false
  def changeset(%Permission{} = permission, attrs) do
    permission
    |> cast(attrs, [:admin_id, :region_id])
    |> validate_required([:admin_id, :region_id])
    |> unique_constraint(:unique, name: :admins__permissions_admin_id_region_id_index)
  end
end
