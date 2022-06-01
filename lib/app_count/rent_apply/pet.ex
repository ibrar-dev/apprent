defmodule AppCount.RentApply.Pet do
  use Ecto.Schema
  import Ecto.Changeset
  @behaviour AppCount.RentApply.ValidatableBehaviour

  @derive {Poison.Encoder,
           only: [
             :id,
             :name,
             :breed,
             :type,
             :weight
           ]}

  schema "rent_apply__pets" do
    field(:name, :string)
    field(:breed, :string)
    field(:type, :string)
    field(:weight, :string)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    timestamps()
  end

  def validation_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:type, :breed, :weight, :name])
    |> validate_required([:type, :breed, :weight, :name])
  end

  @doc false
  def changeset(%AppCount.RentApply.Pet{} = pet, attrs) do
    pet
    |> validation_changeset(attrs)
    |> cast(attrs, [:application_id])
    |> validate_required([:application_id])
  end
end
