defmodule AppCount.Settings.Bank do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings__banks" do
    field :name, :string
    field :routing, :string

    timestamps()
  end

  @doc false
  def changeset(bank, attrs) do
    bank
    |> cast(attrs, [:routing, :name])
    |> validate_required([:routing, :name])
    |> unique_constraint(:unique, name: :accounts__banks_routing_index)
  end
end
