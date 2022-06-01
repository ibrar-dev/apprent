defmodule AppCount.RentApply.MoveIn do
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour AppCount.RentApply.ValidatableBehaviour
  @derive {Poison.Encoder, only: [:expected_move_in, :floor_plan_id, :id, :unit_id]}

  schema "rent_apply__move_ins" do
    field(:expected_move_in, :date)
    belongs_to(:unit, Module.concat(["AppCount.Properties.Unit"]))
    belongs_to(:floor_plan, Module.concat(["AppCount.Properties.FloorPlan"]))

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(move_in, attrs) do
    move_in
    |> cast(attrs, [:expected_move_in, :unit_id, :floor_plan_id])
    |> validate_required([:expected_move_in])
  end

  @doc false
  def changeset(move_in, attrs) do
    move_in
    |> validation_changeset(attrs)
    |> cast(attrs, [:application_id])
    |> validate_required([:application_id])
  end
end
