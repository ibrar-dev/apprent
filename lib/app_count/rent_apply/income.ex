defmodule AppCount.RentApply.Income do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.Income

  schema "rent_apply__incomes" do
    field(:description, :string)
    field(:salary, :decimal)
    field(:application_id, :id)

    timestamps()
  end

  @doc false
  def changeset(%Income{} = income, attrs) do
    income
    |> cast(attrs, [:description, :salary, :application_id])
    |> validate_required([:description, :salary, :application_id])
  end
end
