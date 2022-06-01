defmodule AppCount.Properties.Utils.ResidentParams do
  import Ecto.Query
  alias AppCount.Properties.RecurringLetter
  alias AppCount.Properties.ResidentParams
  alias AppCount.Tenants.Tenant
  alias AppCount.Repo

  #  field :min_balance, :decimal, default: 0 -> process_balance
  #  field :resident_name, :string -> process_names
  #  field :lease_end_date, :naive_datetime -> process_lease_end_date
  #  field :current, :boolean, default: true -> process_status
  #  field :past, :boolean, default: false -> process_status
  #  field :future, :boolean, default: false -> process_status

  def get_residents(id) do
    get_residents_with_params(id)
    |> Enum.map(& &1.id)
  end

  def get_residents_with_params(id) do
    residents_query(id)
    |> process()
  end

  defp residents_query(id) do
    from(
      r in RecurringLetter,
      join: l in assoc(r, :letter_template),
      select: %{
        resident_params: r.resident_params,
        property_id: l.property_id
      },
      where: r.id == ^id,
      limit: 1
    )
    |> Repo.one()
  end

  defp process(%{resident_params: params, property_id: property_id}) do
    process_status(params, property_id)
    |> process_balance(params)
    |> process_names(params)
    |> process_lease_end_date(params)
  end

  ## TO GET ALL THE RESIDENTS THAT HAVE THE STATUS OF THE RECURRING LETTER
  defp process_status(%ResidentParams{current: current, future: future, past: past}, property_id) do
    now = AppCount.current_time()

    status_query(property_id, now)
    |> Repo.all()
    |> Enum.uniq_by(fn t -> t.id end)
    |> Enum.filter(fn t ->
      (current and t.is_current) or (future and t.is_future) or (past and t.is_past)
    end)
  end

  ## TO FILTER OUT ALL RESIDENTS THAT HAVE A BALANCE GREATER THAN THE MIN BALANCE.
  ## Returns all if the min_balance is set to 0 or is nil
  defp process_balance(list, %ResidentParams{min_balance: min_balance}) do
    cond do
      Decimal.cmp(min_balance, 0) == :lt or Decimal.cmp(min_balance, 0) == :eq or
          is_nil(min_balance) ->
        list

      true ->
        list
        |> Enum.map(fn t -> Map.put(t, :balance, AppCount.Accounts.user_balance_total(t.id)) end)
        |> Enum.filter(fn t -> Decimal.cmp(t.balance, min_balance) == :gt end)
    end
  end

  ## TO FILTER OUT ALL THE RESIDENTS THAT HAVE NAMES THAT MATCH THE PARAMS NAME
  ## Returns all if it is nil or an empty string
  defp process_names(list, %ResidentParams{resident_name: resident_name}) do
    cond do
      resident_name == "" or is_nil(resident_name) ->
        list

      true ->
        list
        |> Enum.filter(fn t -> String.match?(t.name, ~r/#{resident_name}/i) end)
    end
  end

  defp process_lease_end_date(list, %ResidentParams{lease_end_date: lease_end_date}) do
    cond do
      is_nil(lease_end_date) ->
        list

      true ->
        Enum.filter(list, fn t ->
          Timex.before?(t.end_date, Timex.shift(lease_end_date, days: 1))
        end)

        #      true -> list
        #              |> lease_query(lease_end_date)
    end
  end

  # TODO fix the logic here, it's not correct
  defp status_query(property_id, now) do
    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      select: %{
        id: t.id,
        is_current: l.start_date <= ^now and is_nil(l.actual_move_out),
        is_past: not is_nil(l.actual_move_out),
        is_future: l.start_date > ^now,
        end_date: l.end_date,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name)
      },
      where: u.property_id == ^property_id,
      distinct: t.id
    )
  end
end
