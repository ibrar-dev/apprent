defmodule AppCount.Maintenance.Offer do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Offer

  schema "maintenance__offers" do
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])
    belongs_to :order, Module.concat(["AppCount.Maintenance.Order"])

    timestamps()
  end

  @doc false
  def changeset(%Offer{} = offer, attrs) do
    offer
    |> cast(attrs, [:order_id, :tech_id])
    |> validate_required([:order_id, :tech_id])
    |> unique_constraint(:unique, name: :maintenance__offers_tech_id_order_id_index)
  end
end
