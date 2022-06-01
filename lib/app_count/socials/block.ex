defmodule AppCount.Socials.Block do
  use Ecto.Schema
  import Ecto.Changeset

  schema "social__blocks" do
    field :blockee_id, :integer
    belongs_to(:tenant, Module.concat(["AppCount.Maintenance.Order"]))

    timestamps()
  end

  @doc false
  def changeset(block, attrs) do
    block
    |> cast(attrs, [:blockee_id, :tenant_id])
    |> validate_required([:blockee_id, :tenant_id])
  end
end
