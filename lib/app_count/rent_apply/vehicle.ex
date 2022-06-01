defmodule AppCount.RentApply.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour AppCount.RentApply.ValidatableBehaviour
  @derive {Poison.Encoder, only: [:color, :license_plate, :state, :make_model]}

  schema "rent_apply__vehicles" do
    field(:color, :string)
    field(:license_plate, :string)
    field(:state, :string)
    field(:make_model, :string)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:make_model, :color, :license_plate, :state])
    |> validate_required([:make_model, :color, :license_plate, :state])
  end

  @doc false
  def changeset(%AppCount.RentApply.Vehicle{} = vehicle, attrs) do
    vehicle
    |> validation_changeset(attrs)
    |> cast(attrs, [:application_id])
    |> validate_required([:application_id])
  end
end
