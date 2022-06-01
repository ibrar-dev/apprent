defmodule AppCount.Properties.Utils.Packages do
  alias AppCount.Repo
  alias AppCount.Properties.Package
  alias AppCount.Properties.Unit
  alias AppCount.Tenants.Tenant
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def list_packages(admin, property_ids \\ nil) do
    property_ids = property_ids || admin.property_ids
    today = AppCount.current_time()

    from(
      p in Package,
      left_join: u in assoc(p, :unit),
      left_join: leases in assoc(u, :leases),
      left_join: tenant in assoc(p, :tenant),
      on: tenant.id == p.tenant_id,
      left_join: prop in assoc(u, :property),
      distinct: p.id,
      select: %{
        id: p.id,
        inserted_at: p.inserted_at,
        updated_at: p.updated_at,
        property_id: prop.id,
        unit_id: u.id,
        condition: p.condition,
        last_emailed: p.last_emailed,
        name: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name),
        package_name: p.name,
        email: tenant.email,
        pin: tenant.package_pin,
        status: p.status,
        type: p.type,
        carrier: p.carrier,
        tracking_number: p.tracking_number,
        unit: u.number,
        admin: p.admin,
        property: prop.name,
        current_tenant: is_nil(leases.actual_move_out) or leases.actual_move_out > ^today
      },
      where:
        u.property_id in ^admin.property_ids and not is_nil(tenant.first_name) and
          tenant.id == p.tenant_id and u.property_id in ^property_ids
    )
    |> Repo.all()
  end

  def tenant_query(tenant_id) do
    from(
      t in Tenant,
      select: %{
        id: t.id,
        email: t.email,
        first_name: t.first_name,
        last_name: t.last_name,
        inserted_at: t.inserted_at
      },
      where: t.id == ^tenant_id
    )
  end

  def create_package(params) do
    new_params = Map.put(params, "last_emailed", AppCount.current_time())

    %Package{}
    |> Package.changeset(new_params)
    |> Repo.insert()
    |> check_status
  end

  def check_status({:ok, %{status: status} = package}) do
    if status == "Undeliverable" do
      raise "endLease"
    else
      send_package_created_email({:ok, package})
    end
  end

  def send_package_created_email({:ok, %{unit_id: unit_id, tenant_id: tenant_id} = package}) do
    unit = Repo.get(Unit, unit_id)
    tenant = Repo.get(Tenant, tenant_id)
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", unit.property_id))

    if tenant do
      AppCountCom.Packages.package_created(property, tenant, package)
      {:ok, package}
    else
      raise "endLease"
    end
  end

  def update_package(id, params) do
    Repo.get(Package, id)
    |> Package.changeset(params)
    |> Repo.update()
  end

  def send_uncollected_package_email(%{tenant_id: tenant_id, id: id, packages: packages} = info) do
    unit = Repo.get(Unit, id)
    tenant = Repo.get(Tenant, tenant_id)
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", unit.property_id))
    AppCountCom.Packages.package_uncollected(property, tenant, info)

    Enum.map(
      packages,
      fn pack ->
        updatedPack = Map.put(pack, "last_emailed", AppCount.current_time())
        update_package(pack["id"], updatedPack)
      end
    )
  end

  def delete_package(id) do
    Repo.get(Package, id)
    |> Repo.delete()
  end

  ####### FUNCTIONS IN JOB DO NOT DELETE ######
  def uncollected_packages() do
    todaysDate = AppCount.current_time()
    two_days_prior = Timex.shift(AppCount.current_time(), days: -2)

    from(
      u in Unit,
      left_join: p in assoc(u, :packages),
      left_join: l in assoc(u, :leases),
      left_join: t in assoc(l, :tenants),
      select: %{
        id: u.id,
        unit: u.number,
        total: count(p.id),
        packages: jsonize(p, [:id, :status, :unit_id, :carrier, :inserted_at]),
        tenant_id: t.id,
        email: t.email
      },
      where: p.last_emailed < ^two_days_prior and p.status == "Pending" and not is_nil(t.email),
      where: l.move_out_date > ^todaysDate or is_nil(l.move_out_date),
      group_by: [u.id, t.id]
    )
    |> Repo.all()
    |> Enum.each(fn info -> send_uncollected_package_email(info) end)
  end

  def return_packages() do
    two_weeks_prior = Timex.shift(AppCount.current_time(), days: -14)

    from(
      p in Package,
      select: p.id,
      where: p.inserted_at < ^two_weeks_prior and p.status == "Pending"
    )
    |> Repo.all()
    |> Enum.each(fn id -> mark_as_moved(id) end)
  end

  defp mark_as_moved(id) do
    params =
      Repo.get(Package, id)
      |> Map.from_struct()
      |> Map.put(:status, "Undeliverable")

    update_package(id, params)
  end

  def package_updates() do
    uncollected_packages()
    return_packages()
  end

  ###########################################

  ############## RESIDENT FUNCTIONS
  def list_resident_packages(tenant_id) do
    from(
      p in Package,
      where: p.tenant_id == ^tenant_id,
      select: %{
        status: p.status,
        condition: p.condition,
        tracking_number: p.tracking_number,
        carrier: p.carrier,
        type: p.type,
        name: p.name,
        notes: p.notes,
        inserted_at: p.inserted_at
      }
    )
    |> Repo.all()
  end
end
