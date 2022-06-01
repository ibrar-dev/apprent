defmodule AppCount.Admins.AdminRole do
  @moduledoc """
    Join table between Admin and Role
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__admin_roles" do
    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :role, AppCount.Admins.Role

    timestamps()
  end

  @doc false
  def changeset(admin_role, attrs) do
    admin_role
    |> cast(attrs, [:admin_id, :role_id])
    |> validate_required([:admin_id, :role_id])
    |> unique_constraint(:duplicate, name: :admin)
  end
end
