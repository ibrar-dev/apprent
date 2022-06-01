defmodule AppCount.Properties.ResidentParams do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  ## These are the parameters used to determine who to send the recurring LetterTemplate to.
  ## When updating this please make sure to also add a query to the utils file.
  embedded_schema do
    field :min_balance, :decimal, default: 0
    field :resident_name, :string
    field :lease_end_date, :date
    field :current, :boolean, default: true
    field :past, :boolean, default: false
    field :future, :boolean, default: false
  end

  @doc false
  def changeset(rp, attrs) when attrs == %{} do
    blank = Map.from_struct(%__MODULE__{})

    rp
    |> cast(blank, [:min_balance, :current, :past, :future])
  end

  def changeset(rp, attrs) do
    rp
    |> cast(attrs, [:min_balance, :resident_name, :lease_end_date, :current, :past, :future])
    |> validate_required([:min_balance, :current, :past, :future])
  end
end
