defmodule AppCount.Accounting.Receipts.ClearLedger do
  import Ecto.Query

  def clear_ledger(lease_ids) do
    from(
      r in AppCount.Accounting.Receipt,
      join: c in assoc(r, :charge),
      where: c.lease_id in ^lease_ids
    )
    |> AppCount.Repo.delete_all()

    lease_ids
  end
end
