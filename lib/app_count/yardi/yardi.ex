defmodule AppCount.Yardi do
  alias AppCount.Repo
  alias AppCount.Tasks.Enqueue
  alias AppCount.Tenants.Tenant
  alias AppCount.Core.ClientSchema
  import Ecto.Query

  def perform_import_residents(client_schema) do
    from(
      s in AppCount.Properties.Setting,
      where: s.integration == "Yardi" and s.sync_residents,
      select: s.property_id
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.each(&import_residents({client_schema, &1}))
  end

  def perform_import_ledgers(client_schema) do
    from(
      s in AppCount.Properties.Setting,
      where: s.integration == "Yardi" and s.sync_ledgers,
      select: s.property_id
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.each(&import_ledgers({client_schema, &1}))
  end

  def import_residents({client_schema, property_id}) do
    desc = "Import residents property ID: #{property_id}"
    arg = ClientSchema.new(client_schema, property_id)
    Enqueue.enqueue(desc, &AppCount.Yardi.ImportResidents.perform/1, [arg], client_schema)
  end

  def import_ledgers({client_schema, property_id}) do
    desc = "Import tenant ledgers for Property: #{property_id}"
    Enqueue.enqueue(desc, &do_import_property_ledgers/1, [property_id], client_schema)
  end

  def do_import_property_ledgers(property_id) do
    from(
      tenant in Tenant,
      join: tenancy in assoc(tenant, :tenancies),
      join: unit in assoc(tenancy, :unit),
      where: unit.property_id == ^property_id,
      where: not is_nil(tenancy.external_id),
      distinct: true,
      select: tenancy.id
    )
    |> AppCount.Repo.all()
    |> Enum.each(&AppCount.Yardi.ImportLedger.perform(property_id, &1))
  end
end
