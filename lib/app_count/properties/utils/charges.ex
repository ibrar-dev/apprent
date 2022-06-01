defmodule AppCount.Properties.Utils.Charges do
  alias AppCount.Repo
  alias AppCount.Properties.Charge
  alias AppCount.Leases.Lease

  def update_charge(admin, id, params) do
    change =
      Repo.get(Charge, id)
      |> Charge.changeset(params)

    if Enum.any?([:from_date, :to_date, :amount, :lease_id], &(!change.changes[&1])) do
      change
      |> log_changes(admin.name)
      |> Repo.update()
      |> update_bill_date
    else
      change
      |> Repo.update()
      |> update_bill_date
    end
  end

  defp log_changes(%{changes: changes} = change, _) when changes == %{}, do: change

  defp log_changes(%{changes: changes} = change, admin) do
    changed_attrs = Map.merge(changes, %{admin: admin, time: AppCount.current_time()})
    edits = change.data.edits ++ [changed_attrs]
    Ecto.Changeset.change(change, %{edits: edits})
  end

  def update_bill_date({:error, _} = e), do: e

  def update_bill_date({:ok, %{from_date: from_date} = charge}) do
    next_bill_date =
      cond do
        is_nil(from_date) or from_date < AppCount.current_date() ->
          AppCount.Jobs.Scheduler.next_ts(charge.schedule) |> DateTime.from_unix!()

        true ->
          from_date
      end

    Charge.changeset(charge, %{next_bill_date: next_bill_date})
    |> Repo.update()
  end

  def create_charge(params) do
    sample =
      Map.keys(params)
      |> hd

    lease = Repo.get(Lease, params[to_key(sample, "lease_id")])

    #
    #    start_d = AppCount.current_date() |> Timex.shift(months: 1) |> Timex.beginning_of_month()

    %Charge{}
    |> Charge.changeset(
      Map.put(
        params,
        to_key(sample, "next_bill_date"),
        #        params[to_key(sample, "from_date")] || start_d
        params[to_key(sample, "from_date")] || lease.start_date
      )
    )
    |> Repo.insert()
  end

  def delete_charge(id) do
    charge =
      Repo.get(Charge, id)
      |> Repo.preload(:lease)

    Repo.delete(charge)
  end

  defp to_key(sample, key) when is_binary(sample), do: "#{key}"
  defp to_key(sample, key) when is_atom(sample), do: :"#{key}"
end
