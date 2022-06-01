defmodule AppCount.Admins.Action do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__actions" do
    field(:description, :string)
    field(:ip, :string)
    field(:type, :string)
    field(:params, :map)
    belongs_to(:admin, AppCount.Admins.Admin)
    timestamps()
  end

  @doc false
  def changeset(action, attrs) do
    action
    |> cast(attrs, [:ip, :description, :params, :admin_id, :type])
    |> foreign_key_constraint(:admin_id)
    |> validate_required([:ip, :description, :params, :admin_id, :type])
  end
end
