defmodule AppCount.Leasing.LeaseRepo do
  use AppCount.Core.GenericRepo, schema: AppCount.Leasing.Lease

  alias AppCount.Core.ClientSchema

  def leases_by_customer_id(%ClientSchema{
        name: client_schema,
        attrs: customer_id
      }) do
    from(lease in @schema, where: lease.customer_ledger_id == ^customer_id)
    |> Repo.all(prefix: client_schema)
  end

  def most_current_lease_query(date \\ AppCount.current_date()) do
    from(
      lease in @schema,
      distinct: lease.customer_ledger_id,
      where: lease.start_date <= ^date,
      order_by: [desc: lease.start_date]
    )
  end

  def last_lease_query() do
    from(
      lease in @schema,
      distinct: lease.customer_ledger_id,
      order_by: [desc: lease.start_date]
    )
  end
end
