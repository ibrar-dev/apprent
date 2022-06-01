defmodule AppCount.Prospects.TrafficSource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__traffic_sources" do
    field :name, :string
    field :type, :string
    has_many :prospects, Module.concat(["AppCount.Prospects.Prospect"])

    timestamps()
  end

  @doc false
  def changeset(traffic_source, attrs) do
    traffic_source
    |> cast(attrs, [:name, :type])
    |> validate_required([:name, :type])
  end
end
