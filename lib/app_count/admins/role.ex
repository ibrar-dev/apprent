defmodule AppCount.Admins.Role do
  @moduledoc """
    Defines roles for admins. Roles are assigned to admins via Admins.AdminRole
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__roles" do
    field :name, :string
    field :permissions, AppCount.EctoTypes.PermissionList
    has_many :admin_roles, AppCount.Admins.AdminRole
    many_to_many :admins, AppCount.Admins.Admin, join_through: AppCount.Admins.AdminRole

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :permissions])
    |> validate_required([:name, :permissions])
    |> validate_permissions
  end

  def validate_permissions(changeset) do
    permissions = Map.get(changeset.changes, :permissions, %{})

    valid =
      permissions
      |> Map.values()
      |> Enum.all?(&(&1 in [:read, :write, "read", "write"]))

    if valid, do: changeset, else: add_error(changeset, :invalid_action, "Invalid permission")
  end
end
