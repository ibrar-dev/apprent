defmodule AppCount.Maintenance.Part do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__parts" do
    field :name, :string
    field :status, :string
    belongs_to :order, Module.concat(["AppCount.Maintenance.Order"])

    timestamps()
  end

  @doc false
  def changeset(part, attrs) do
    part
    |> cast(attrs, [:name, :status, :order_id])
    |> validate_required([:name, :order_id])
  end
end
