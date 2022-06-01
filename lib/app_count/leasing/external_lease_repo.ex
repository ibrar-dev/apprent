defmodule AppCount.Leasing.ExternalLeaseRepo do
  alias AppCount.Core.ClientSchema
  use AppCount.Core.GenericRepo, schema: AppCount.Leasing.ExternalLease

  def get_pending_leases_for(%ClientSchema{
        name: client_schema,
        attrs: unit_id
      }) do
    from(
      lease in @schema,
      where: lease.unit_id == ^unit_id,
      where: lease.executed == false,
      where: lease.archived == false
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_all_pending_leases(%ClientSchema{
        name: client_schema
      }) do
    from(
      lease in @schema,
      where: lease.executed == false,
      where: lease.archived == false
    )
    |> Repo.all(prefix: client_schema)
  end
end
