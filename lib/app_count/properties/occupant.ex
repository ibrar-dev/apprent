defmodule AppCount.Properties.Occupant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__occupants" do
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :phone, :string
    field :email, :string
    belongs_to :lease, Module.concat(["AppCount.Leases.Lease"])

    timestamps()
  end

  @doc false
  def changeset(persons, attrs) do
    persons
    |> cast(attrs, [:first_name, :middle_name, :last_name, :phone, :email, :lease_id])
    |> validate_required([:first_name, :last_name, :lease_id])
  end
end
