defmodule AppCount.Accounting.Receipts.GetLedger do
  @moduledoc """
    Fetches all ledger data for a given lease id
  """
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Leases.Lease

  def ledger_for(lease_id) do
    renewal_ids(lease_id, [lease_id])
    |> previous_lease_ids(lease_id)
  end

  def renewal_ids(lease_id, lease_ids_accumulator) do
    from(
      l in Lease,
      where: l.id == ^lease_id,
      select: l.renewal_id
    )
    |> Repo.one()
    |> maybe_recurse_renewal(lease_ids_accumulator)
  end

  def previous_lease_ids(accumulator, lease_id) do
    from(
      l in Lease,
      where: l.renewal_id == ^lease_id,
      select: l.id
    )
    |> Repo.one()
    |> maybe_recurse_previous(accumulator)
  end

  def maybe_recurse_renewal(nil, acc), do: acc
  def maybe_recurse_renewal(renewal_id, acc), do: renewal_ids(renewal_id, acc ++ [renewal_id])

  def maybe_recurse_previous(nil, acc), do: acc

  def maybe_recurse_previous(previous_id, acc),
    do: previous_lease_ids(acc ++ [previous_id], previous_id)
end
