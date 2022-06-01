defmodule AppCount.Leases.Utils.Charges do
  import Ecto.Query
  alias Ecto.Multi
  alias AppCount.Repo
  alias AppCount.Properties.Charge
  alias AppCount.Leases.Lease

  def update_charges(admin, lease_id, params) do
    case validate_params(params) do
      true -> do_update_charges(admin, lease_id, params)
      {:error, _} = e -> e
    end
  end

  defp do_update_charges(admin, lease_id, params) do
    params
    |> Enum.with_index()
    |> Enum.reduce(
      Multi.new(),
      fn {charge, index}, multi ->
        Multi.insert_or_update(
          multi,
          :"charge_#{index}",
          insert_or_update_charge(admin, Map.put(charge, "lease_id", lease_id))
        )
      end
    )
    |> Multi.run(
      :deleted,
      fn _repo, cs ->
        charge_ids =
          Map.values(cs)
          |> Enum.map(& &1.id)

        r =
          from(c in Charge, where: c.id not in ^charge_ids and c.lease_id == ^lease_id)
          |> Repo.delete_all()

        {:ok, r}
      end
    )
    |> Repo.transaction()
  end

  defp insert_or_update_charge(admin, %{"id" => id} = params) do
    change =
      Repo.get(Charge, id)
      |> Charge.changeset(params)

    if Enum.any?([:from_date, :to_date, :amount, :lease_id], &(!change.changes[&1])) do
      change
      |> log_changes(admin.name)
    else
      change
    end
  end

  defp insert_or_update_charge(_admin, params) do
    sample =
      Map.keys(params)
      |> hd

    lease = Repo.get(Lease, params[to_key(sample, "lease_id")])

    %Charge{}
    |> Charge.changeset(
      Map.put(
        params,
        to_key(sample, "next_bill_date"),
        params[to_key(sample, "from_date")] || lease.start_date
      )
    )
  end

  def delete_charge(id) do
    charge =
      Repo.get(Charge, id)
      |> Repo.preload(:lease)

    Repo.delete(charge)
  end

  defp to_key(sample, key) when is_binary(sample), do: "#{key}"
  defp to_key(sample, key) when is_atom(sample), do: :"#{key}"

  defp log_changes(%{changes: changes} = change, _) when changes == %{}, do: change

  defp log_changes(%{changes: changes} = change, admin) do
    changed_attrs = Map.merge(changes, %{admin: admin, time: AppCount.current_time()})
    edits = change.data.edits ++ [changed_attrs]
    Ecto.Changeset.change(change, %{edits: edits})
  end

  defp validate_params(params) do
    rent_code = AppCount.Accounting.SpecialAccounts.get_charge_code(:rent)
    rent_charges = Enum.filter(params, &(&1["charge_code_id"] == rent_code.id))

    cond do
      Enum.empty?(rent_charges) ->
        {:error, "No rent charge"}

      Enum.all?(rent_charges, & &1["to_date"]) ->
        {:error, "Must have at least one open ended rent charge"}

      true ->
        true
    end
  end
end
