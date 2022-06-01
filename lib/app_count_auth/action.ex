defmodule AppCountAuth.Action do
  use Ecto.Schema
  import Ecto.Changeset

  schema "actions" do
    field :description, :string
    field :permission_type, :string
    belongs_to :module, AppCountAuth.Module

    timestamps()
  end

  @doc false
  def changeset(action, attrs) do
    action
    |> cast(attrs, [:description, :permission_type, :module_id])
    |> validate_required([:description, :permission_type, :module_id])
    |> validate_inclusion(:permission_type, ["read-write", "yes-no"],
      message: "permission type invalid"
    )
  end
end
