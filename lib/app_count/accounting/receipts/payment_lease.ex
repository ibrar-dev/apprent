defmodule AppCount.Accounting.Receipts.PaymentLease do
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  import Ecto.Query

  def match_payment_to_lease(%{tenant_id: nil}), do: nil

  def match_payment_to_lease(payment) do
    lease_id = most_recent_lease_before_payment(payment) || first_lease_for_tenant(payment)

    if lease_id do
      payment
      |> AppCount.Ledgers.Payment.changeset(%{lease_id: lease_id})
      |> Repo.update!()
    end
  end

  defp most_recent_lease_before_payment(payment) do
    lease_query(payment.tenant_id)
    |> where([l], l.start_date <= ^payment.inserted_at)
    |> order_by([l], desc: l.start_date)
    |> Repo.one()
  end

  defp first_lease_for_tenant(payment) do
    lease_query(payment.tenant_id)
    |> order_by([l], asc: l.start_date)
    |> Repo.one()
  end

  defp lease_query(tenant_id) do
    from(
      l in Lease,
      join: t in assoc(l, :tenants),
      where: t.id == ^tenant_id,
      select: l.id,
      limit: 1
    )
  end
end
