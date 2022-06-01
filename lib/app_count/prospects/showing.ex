defmodule AppCount.Prospects.Showing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__showings" do
    field :date, :date
    field :start_time, :integer
    field :end_time, :integer
    field :cancellation, :date
    belongs_to :prospect, Module.concat(["AppCount.Prospects.Prospect"])
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :unit, Module.concat(["AppCount.Properties.Unit"])

    timestamps()
  end

  @doc false
  def changeset(showing, attrs) do
    showing
    |> cast(attrs, [
      :date,
      :prospect_id,
      :property_id,
      :unit_id,
      :start_time,
      :end_time,
      :cancellation
    ])
    |> validate_required([:date, :prospect_id, :property_id, :start_time, :end_time])
    |> exclusion_constraint(:scheduling_conflict, name: :scheduling_conflict, message: "")
  end
end
