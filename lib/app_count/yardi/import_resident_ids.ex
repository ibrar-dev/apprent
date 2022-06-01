defmodule AppCount.Yardi.ImportResidentIds do
  require Logger
  alias AppCount.Repo
  alias AppCount.Tenants
  alias AppCount.Properties.Property
  alias AppCount.Properties.Processors
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def perform(property, gateway \\ Yardi.Gateway)

  def perform(%Property{external_id: external_id, id: id} = property, gateway)
      when is_binary(external_id) do
    credentials = Processors.processor_credentials(ClientSchema.new("dasmen", id), "management")

    external_id
    |> gateway.import_residents(credentials)
    |> perform_import(property)
  end

  def perform(%Property{} = p, _), do: raise("No external ID found for property #{p.name}")

  def perform(property_id, gateway), do: perform(Repo.get(Property, property_id), gateway)

  def perform_import({:error, error}, _property), do: log("Error importing IDs: #{error}")

  def perform_import({:ok, tenant_structs}, property) do
    log("Initializing External ID import for #{property.name}...")

    processable =
      tenant_structs
      |> Enum.filter(&can_import/1)
      |> Enum.group_by(&"#{&1.first_name}|#{&1.last_name}|#{&1.email}")

    tenant_dict =
      from(
        t in Tenants.Tenant,
        join: l in assoc(t, :leases),
        join: u in assoc(l, :unit),
        where: u.property_id == ^property.id,
        select: map(t, [:id, :first_name, :last_name, :email])
      )
      |> Repo.all()
      |> Enum.into(%{}, &{"#{&1.first_name}|#{&1.last_name}|#{&1.email}", &1.id})

    Enum.each(processable, fn {data, [%{external_id: external_id} | _]} ->
      case tenant_dict[data] do
        nil -> nil
        id -> AppCount.Tenants.update_tenant(id, %{external_id: external_id})
      end
    end)
  end

  def can_import(tenant_struct) do
    [:first_name, :last_name, :email]
    |> Enum.all?(&Map.get(tenant_struct, &1))
  end

  defp log(message) do
    Logger.info(message)
    AppCount.Tasks.Task.log(message)
  end
end
