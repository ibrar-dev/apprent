defmodule AppCount.RentApply.ApprovalParams do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :start_date, :date
    field :end_date, :date
    field :persons, {:array, :map}, default: []
    field :unit_id, :integer
    field :charges, {:array, :map}, default: []
    field :deposit_amount, :decimal
    field :deposit_type, :string
  end

  @doc false
  def changeset(job, attrs) when attrs == %{} do
    blank = Map.from_struct(%__MODULE__{})

    job
    |> cast(blank, [
      :start_date,
      :end_date,
      :persons,
      :unit_id,
      :charges,
      :deposit_amount,
      :deposit_type
    ])
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [
      :start_date,
      :end_date,
      :persons,
      :unit_id,
      :charges,
      :deposit_amount,
      :deposit_type
    ])
    |> validate_required([:start_date, :end_date, :persons, :unit_id, :charges])
  end

  def rent(%__MODULE__{charges: c}) do
    Enum.reduce_while(c, nil, fn charge, rent ->
      if charge["name"] == "Rent" do
        {:halt, charge["amount"]}
      else
        {:cont, rent}
      end
    end)
  end
end
