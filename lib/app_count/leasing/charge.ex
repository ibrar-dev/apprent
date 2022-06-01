defmodule AppCount.Leasing.Charge do
  use Ecto.Schema
  import Ecto.Changeset

  @default_schedule %{
    hour: [0],
    minute: [0],
    day: [1],
    year: nil,
    month: nil,
    week: nil,
    wday: nil
  }

  schema "leasing__charges" do
    field :amount, :decimal
    field :edits, {:array, :map}
    field :from_date, :date
    field :last_bill_date, :date
    field :to_date, :date
    embeds_one :schedule, AppCount.Jobs.Schedule, on_replace: :update
    belongs_to :lease, AppCount.Leasing.Lease
    belongs_to :charge_code, AppCount.Ledgers.ChargeCode

    timestamps()
  end

  def default_charge_schedule() do
    %AppCount.Jobs.Schedule{}
    |> AppCount.Jobs.Schedule.changeset(@default_schedule)
    |> Ecto.Changeset.apply_changes()
  end

  @doc false
  def changeset(charge, attrs) do
    charge
    |> cast(attrs, [
      :amount,
      :from_date,
      :to_date,
      :last_bill_date,
      :edits,
      :charge_code_id,
      :lease_id
    ])
    |> cast_schedule(attrs)
    |> validate_required([:amount, :schedule, :charge_code_id, :lease_id])
  end

  defp cast_schedule(cs, %{schedule: _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, %{"schedule" => _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(%{data: %{schedule: s}} = cs, _) when not is_nil(s), do: cs

  defp cast_schedule(cs, attrs) do
    cs
    |> Map.put(:params, Map.put(cs.params, "schedule", @default_schedule))
    |> cast_schedule(Map.merge(attrs, %{"schedule" => @default_schedule}))
  end
end
