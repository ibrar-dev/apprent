defmodule AppCount.Prospects.Opening do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__openings" do
    field :wday, :integer
    field :showing_slots, :integer
    field :start_time, :integer
    field :end_time, :integer
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:wday, :start_time, :end_time, :showing_slots, :property_id])
    |> validate_required([:wday, :start_time, :end_time, :showing_slots, :property_id])
  end
end
