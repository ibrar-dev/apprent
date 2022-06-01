defmodule AppCount.Properties.Eviction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__evictions" do
    field :court_date, :date
    field :file_date, :date
    field :notes, :string
    belongs_to :lease, Module.concat(["AppCount.Leases.Lease"])

    timestamps()
  end

  @doc false
  def changeset(eviction, attrs) do
    eviction
    |> cast(attrs, [:court_date, :file_date, :notes, :lease_id])
    |> validate_required([:lease_id, :file_date])
    |> unique_constraint(:unique, name: :properties__evictions_lease_id_index)
  end
end
