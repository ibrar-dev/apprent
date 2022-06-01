defmodule AppCount.Messaging.Utils.Residents do
  import Ecto.Query
  alias AppCount.Tenants.Tenant
  alias AppCount.Leases.Lease
  alias AppCount.RentApply.Person
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  def get_residents_by_type(admin, "all") do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      where: not is_nil(t.email) and u.property_id in ^property_ids,
      select: %{
        id: t.id,
        email: t.email,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        checked: true,
        property_id: u.property_id,
        property: p.name
      },
      distinct: t.id
    )
    |> Repo.all()
  end

  def get_residents_by_type(admin, "all_current") do
    now = AppCount.current_time()
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      where: l.start_date <= ^now and is_nil(l.actual_move_out),
      where: not is_nil(t.email) and u.property_id in ^property_ids,
      select: %{
        id: t.id,
        email: t.email,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        checked: true,
        property_id: u.property_id,
        unit: u.number,
        property: p.name
      },
      distinct: t.id
    )
    |> Repo.all()
  end

  def get_residents_by_type(admin, "all_past") do
    now = AppCount.current_time()
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      where: l.start_date <= ^now and not is_nil(l.actual_move_out),
      where: not is_nil(t.email) and u.property_id in ^property_ids,
      select: %{
        id: t.id,
        email: t.email,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        checked: true,
        property_id: u.property_id,
        type: "past",
        unit: u.number,
        property: p.name
      },
      distinct: t.id
    )
    |> Repo.all()
  end

  ## Gets applicants that have been approved and their move in date is in the future. Returns only their name, email and ID
  def get_residents_by_type(admin, "all_future") do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      p in Person,
      join: a in assoc(p, :application),
      join: prop in assoc(a, :property),
      where: p.status == "Lease Holder" and not is_nil(p.email),
      where: a.property_id in ^property_ids and a.status in ["approved", "conditional"],
      select: %{
        id: p.id,
        email: p.email,
        name: p.full_name,
        checked: true,
        property_id: a.property_id,
        property: prop.name,
        type: "future"
      }
    )
    |> Repo.all()
  end

  def get_residents_by_type(_, property_id, "future") do
    from(
      p in Person,
      join: a in assoc(p, :application),
      join: prop in assoc(a, :property),
      where: p.status == "Lease Holder" and not is_nil(p.email),
      where: a.property_id == ^property_id and a.status in ["approved", "conditional"],
      select: %{
        id: p.id,
        email: p.email,
        name: p.full_name,
        checked: true,
        property_id: a.property_id,
        property: prop.name,
        type: "future"
      }
    )
    |> Repo.all()
  end

  def get_residents_by_type(admin, property_id, "current") do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    lease_query =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        join: u in assoc(l, :unit),
        where: u.property_id == ^property_id and u.property_id in ^property_ids,
        select: %{
          id: l.id,
          tenant_id: o.tenant_id,
          unit: u.number
        }
      )
      |> filter_query("current", AppCount.current_time())

    from(
      t in Tenant,
      join: l in subquery(lease_query),
      on: l.tenant_id == t.id,
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        checked: true,
        property_id: ^property_id,
        type: "current",
        unit: l.unit,
        email: t.email,
        #                amount: 0.00,
        lease_id: l.id
      },
      distinct: t.id
    )
    |> Repo.all()
  end

  def get_residents_csv(property_id) do
    now = AppCount.current_time()

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      join: u in assoc(l, :unit),
      where:
        is_nil(l.move_out_date) and l.start_date <= ^now and is_nil(l.renewal_id) and
          not is_nil(t.email),
      where: u.property_id == ^property_id,
      select: [
        t.email,
        t.first_name,
        t.last_name,
        u.number
      ]
    )
    |> Repo.all()
    |> save_to_csv
  end

  defp save_to_csv(users) do
    path = "/tmp/csvs/#{UUID.uuid4()}"
    File.mkdir_p(path)
    file = File.open!("#{path}/users.csv", [:write, :utf8])

    users
    |> CSV.encode()
    |> Enum.each(&IO.write(file, &1))

    output = File.read!("#{path}/users.csv")
    File.rm_rf!(path)
    output
  end

  defp filter_query(query, "current", now),
    do: where(query, [l], l.start_date <= ^now and is_nil(l.actual_move_out))

  defp filter_query(query, "past", now),
    do: where(query, [l], l.actual_move_out > ^now and not is_nil(l.actual_move_out))

  defp filter_query(query, "future", now), do: where(query, [l], l.start_date > ^now)
end
