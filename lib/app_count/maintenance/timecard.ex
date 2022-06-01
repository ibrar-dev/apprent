defmodule AppCount.Maintenance.Timecard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__timecards" do
    field :start_location, :map
    field :end_location, :map
    field :start_ts, :integer
    field :end_ts, :integer
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])

    timestamps()
  end

  @doc false
  def changeset(clock, attrs) do
    clock
    |> cast(attrs, [:start_ts, :end_ts, :start_location, :end_location, :tech_id])
    |> validate_required([:start_ts, :tech_id])
  end
end
