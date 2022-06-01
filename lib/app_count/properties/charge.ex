defmodule AppCount.Properties.Charge do
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

  schema "properties__charges" do
    field :amount, :decimal
    field :next_bill_date, :date
    field :from_date, :date
    field :to_date, :date
    field(:edits, {:array, :map})
    embeds_one :schedule, AppCount.Jobs.Schedule, on_replace: :update
    belongs_to :lease, Module.concat(["AppCount.Leases.Lease"])
    belongs_to :charge_code, Module.concat(["AppCount.Ledgers.ChargeCode"])

    timestamps()
  end

  @doc false
  def changeset(charge, attrs) do
    charge
    |> cast(attrs, [
      :amount,
      :lease_id,
      :charge_code_id,
      :from_date,
      :to_date,
      :next_bill_date,
      :edits
    ])
    |> cast_schedule(attrs)
    |> validate_required([:amount, :schedule, :lease_id, :charge_code_id, :next_bill_date])
    |> validate_dates
    |> check_constraint(:valid_dates, name: :lease_charges_valid_dates)
    |> check_constraint(:non_zero, name: :non_zero_amount)
  end

  defp validate_dates(changeset) do
    lease =
      AppCount.Repo.get(
        AppCount.Leases.Lease,
        Map.get(changeset.changes, :lease_id) || changeset.data.lease_id
      )

    Enum.reduce(
      [:from_date, :to_date],
      changeset,
      fn field, cs -> validate_date(field, cs, lease) end
    )
  end

  defp validate_date(:from_date, changeset, lease) do
    validate_change(
      changeset,
      :from_date,
      fn _, value ->
        cond do
          Date.compare(value, lease.start_date) == :lt ->
            [from_date: "cannot be before lease start"]

          Date.compare(value, lease.end_date) == :gt ->
            [from_date: "cannot be after lease end"]

          true ->
            []
        end
      end
    )
  end

  defp validate_date(:to_date, changeset, lease) do
    validate_change(
      changeset,
      :to_date,
      fn _, value ->
        cond do
          Date.compare(value, lease.end_date) == :gt ->
            [to_date: "cannot be after lease end"]

          Date.compare(value, lease.start_date) == :lt ->
            [to_date: "cannot be before lease start"]

          true ->
            []
        end
      end
    )
  end

  defp cast_schedule(cs, %{schedule: _}), do: cast_embed(cs, :schedule)
  defp cast_schedule(cs, %{"schedule" => _}), do: cast_embed(cs, :schedule)

  defp cast_schedule(
         %{
           data: %{
             schedule: s
           }
         } = cs,
         _
       )
       when not is_nil(s),
       do: cs

  defp cast_schedule(cs, attrs) do
    cs
    |> Map.put(:params, Map.put(cs.params, "schedule", @default_schedule))
    |> cast_schedule(Map.merge(attrs, %{"schedule" => @default_schedule}))
  end
end
