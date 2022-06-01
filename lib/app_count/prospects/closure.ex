defmodule AppCount.Prospects.Closure do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__closures" do
    field :date, :date
    field :start_time, :integer
    field :end_time, :integer
    field :reason, :string
    field :admin, :string
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])

    timestamps()
  end

  @doc false
  def changeset(closure, attrs) do
    closure
    |> cast(attrs, [:date, :start_time, :end_time, :reason, :admin, :property_id])
    |> validate_required([:date, :start_time, :end_time, :reason, :admin, :property_id])
    |> check_constraint(:end_time,
      name: :closures_end_after_start,
      message: "End time cannot be before start time"
    )
  end
end
