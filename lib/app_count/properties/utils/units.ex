defmodule AppCount.Properties.Utils.Units do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Properties.Unit
  alias AppCount.Properties.UnitFeature
  alias AppCount.Leasing.Charge
  alias AppCount.Properties.FloorPlan
  alias AppCount.Leasing.Lease
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Reports.Queries
  alias AppCount.Core.ClientSchema

  @lease_fields [
    :actual_move_in,
    :actual_move_out,
    :charges,
    :end_date,
    :id,
    :start_date,
    :tenants
  ]

  def list_units(admin, property_id) do
    current_date = AppCount.current_date()

    from(
      u in Unit,
      where: u.property_id == ^property_id and u.property_id in ^admin.property_ids,
      left_join: l in subquery(lease_query(property_id)),
      on: l.unit_id == u.id,
      left_join: s in subquery(Queries.full_unit_status(property_id, current_date)),
      on: s.id == u.id,
      left_join: mr in subquery(Queries.market_rent(property_id, AppCount.current_date())),
      on: mr.unit_id == u.id,
      select: map(u, [:id, :number, :area]),
      select_merge: %{
        status: s.status,
        market_rent: mr.market_rent,
        floor_plan: mr.floor_plan,
        current_lease: [],
        future_leases: [],
        past_leases: [],
        leases:
          jsonize(l, [
            :id,
            :tenants,
            :haprent,
            :start_date,
            #            :end_date,
            :actual_move_in,
            :actual_move_out,
            :current_rent,
            :expected_move_out
          ])
      },
      group_by: [u.id, s.status, mr.market_rent, mr.floor_plan],
      distinct: u.id
    )
    |> Repo.all(prefix: admin.client_schema)
    |> Enum.sort(&(&1.number < &2.number))
    |> Enum.map(&sort_leases(&1))
  end

  # List all rentable units for a given property
  def list_rentable(%AppCount.Core.ClientSchema{name: client_schema, attrs: %{} = admin}) do
    ClientSchema.new(
      client_schema,
      Admins.property_ids_for(ClientSchema.new(client_schema, admin))
    )
    |> list_rentable()
  end

  def list_rentable(%AppCount.Core.ClientSchema{name: client_schema, attrs: property_ids}) do
    from(
      u in Unit,
      left_join: t in assoc(u, :tenancies),
      left_join: f in assoc(u, :features),
      left_join: p in assoc(u, :property),
      left_join: s in assoc(p, :setting),
      select: %{
        id: u.id,
        property_id: u.property_id,
        property_name: p.name,
        number: u.number,
        status: u.status,
        default_price: fragment("? + (? * ?)", sum(f.price), s.area_rate, u.area),
        prices: jsonize(f, [:price])
      },
      group_by: [u.id, s.area_rate, p.id],
      where: is_nil(f.stop_date) or is_nil(f.id),
      where: u.property_id in ^property_ids,
      having: count(t.id) == 0 or fragment("bool_and(? IS NOT NULL)", t.actual_move_out),
      where: u.status not in ["DOWN", "MODEL"] or is_nil(u.status)
    )
    |> Repo.all(prefix: client_schema)
  end

  # TODO:SCHEMA remove function when the call rent application controller is fixed
  def list_rentable(property_ids) do
    from(
      u in Unit,
      left_join: t in assoc(u, :tenancies),
      left_join: f in assoc(u, :features),
      left_join: p in assoc(u, :property),
      left_join: s in assoc(p, :setting),
      select: %{
        id: u.id,
        property_id: u.property_id,
        property_name: p.name,
        number: u.number,
        status: u.status,
        default_price: fragment("? + (? * ?)", sum(f.price), s.area_rate, u.area),
        prices: jsonize(f, [:price])
      },
      group_by: [u.id, s.area_rate, p.id],
      where: is_nil(f.stop_date) or is_nil(f.id),
      where: u.property_id in ^property_ids,
      having: count(t.id) == 0 or fragment("bool_and(? IS NOT NULL)", t.actual_move_out),
      where: u.status not in ["DOWN", "MODEL"] or is_nil(u.status)
    )
    |> Repo.all()
  end

  def list_units_min(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        p_ids,
        nil
      ) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))
    p_ids = p_ids || property_ids

    from(
      u in Unit,
      join: p in assoc(u, :property),
      where: u.property_id in ^property_ids,
      where: u.property_id in ^p_ids,
      select: %{
        id: u.id,
        number: u.number,
        property: p.name,
        property_id: p.id
      }
    )
    |> Repo.all(prefix: client_schema)
  end

  def list_units_min(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        nil,
        start_date
      ) do
    start_date = Timex.parse!(start_date, "{YYYY}-{M}-{D}")
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      u in Unit,
      left_join: f in assoc(u, :features),
      left_join: p in assoc(u, :property),
      left_join: t in assoc(u, :tenancies),
      select: %{
        id: u.id,
        number: u.number,
        property: p.name,
        property_id: p.id
      },
      distinct: u.id,
      where: u.status != "MODEL" or is_nil(u.status),
      where: u.property_id in ^property_ids,
      where:
        is_nil(t.id) or (not is_nil(t.expected_move_out) and t.expected_move_out < ^start_date) or
          not is_nil(t.actual_move_out)
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_unit(%ClientSchema{name: client_schema, attrs: params}) do
    Unit.changeset(%Unit{}, params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_unit(id, %{"feature_ids" => ids} = params) do
    set_unit_features(id, ids)
    update_unit(id, Map.delete(params, "feature_ids"))
  end

  def update_unit(id, params) do
    Repo.get(Unit, id)
    |> Unit.changeset(params)
    |> Repo.update()
  end

  def delete_unit(id) do
    Repo.get(Unit, id)
    |> Repo.delete()
  end

  def get_unit(nil), do: nil

  def get_unit(id) do
    from(
      u in Unit,
      left_join: f in assoc(u, :features),
      left_join: plan in assoc(u, :floor_plan),
      left_join: fp in assoc(plan, :features),
      left_join: dc in assoc(plan, :default_charges),
      left_join: cc in assoc(dc, :charge_code),
      where: is_nil(f.stop_date),
      where: is_nil(fp.stop_date),
      where: u.id == ^id,
      select: %{
        id: u.id,
        number: u.number,
        status: u.status,
        uuid: u.uuid,
        area: u.area,
        address: u.address,
        property_id: u.property_id,
        floor_plan_id: u.floor_plan_id,
        market_rent: coalesce(f.price, 0) + coalesce(fp.price, 0),
        default_charges: jsonize(dc, [:id, :price, :default_charge, {:charge_code, cc.name}])
      },
      group_by: [u.id, f.price, fp.price]
    )
    |> Repo.one()
  end

  def unit_rent(unit) do
    from(
      u in Unit,
      where: u.id == ^unit.id,
      left_join: f in assoc(u, :features),
      left_join: plan in assoc(u, :floor_plan),
      left_join: fp in assoc(plan, :features),
      where: is_nil(f.stop_date),
      where: is_nil(fp.stop_date),
      select:
        fragment(
          "? + ?",
          sum(fragment("CASE WHEN ? IS NULL THEN 0 ELSE ? END", f.price, f.price)),
          sum(fragment("CASE WHEN ? IS NULL THEN 0 ELSE ? END", fp.price, fp.price))
        )
    )
    |> Repo.one()
  end

  def show_unit(admin, id) do
    unit_query(admin)
    |> where([u], u.id == ^id)
    |> Repo.all(prefix: admin.client_schema)
    |> hd
  end

  def get_available_units(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_id},
        start_date
      ) do
    floor_plan_query = floor_plan_sub()

    feature_query = feature_sub()

    from(
      u in Unit,
      left_join: tenancy in assoc(u, :tenancies),
      left_join: f in subquery(feature_query),
      on: f.unit_id == u.id,
      left_join: plan in subquery(floor_plan_query),
      on: plan.id == u.floor_plan_id,
      left_join: p in assoc(u, :property),
      left_join: s in assoc(p, :setting),
      left_join: fp in assoc(u, :floor_plan),
      left_join: dfl in assoc(fp, :default_charges),
      left_join: cc in assoc(dfl, :charge_code),
      select: %{
        id: u.id,
        number: u.number,
        move_out_date: tenancy.expected_move_out,
        default_lease_charges:
          jsonize(dfl, [:id, :price, :default_charge, :charge_code_id, {:charge_code, cc.name}]),
        market_rent:
          sum(coalesce(f.price, 0)) + sum(coalesce(plan.price, 0)) + u.area * s.area_rate
      },
      group_by: [u.id, p.id, tenancy.expected_move_out, s.id],
      where:
        u.property_id == ^property_id and
          (is_nil(tenancy.id) or
             (not is_nil(tenancy.expected_move_out) and tenancy.expected_move_out < ^start_date) or
             not is_nil(tenancy.actual_move_out))
    )
    |> Repo.all(prefix: client_schema)
  end

  defp floor_plan_sub do
    from(
      p in FloorPlan,
      left_join: f in assoc(p, :features),
      select: %{
        id: p.id,
        price: sum(f.price)
      },
      where: is_nil(f.stop_date),
      group_by: p.id
    )
  end

  defp feature_sub do
    from(
      uf in UnitFeature,
      left_join: f in assoc(uf, :feature),
      select: %{
        unit_id: uf.unit_id,
        price: sum(f.price)
      },
      where: is_nil(f.stop_date),
      group_by: uf.unit_id
    )
  end

  def market_rent(%ClientSchema{
        name: client_schema,
        attrs: unit_id
      }) do
    floor_plan_query = floor_plan_sub()

    feature_query = feature_sub()

    from(
      u in Unit,
      left_join: f in subquery(feature_query),
      on: f.unit_id == u.id,
      left_join: plan in subquery(floor_plan_query),
      on: plan.id == u.floor_plan_id,
      left_join: p in assoc(u, :property),
      left_join: s in assoc(p, :setting),
      where: u.id == ^unit_id,
      select: sum(coalesce(f.price, 0)) + sum(coalesce(plan.price, 0)) + u.area * s.area_rate,
      group_by: [u.id, s.id]
    )
    |> Repo.one(prefix: client_schema)
  end

  ## THIS FUNCTION IS USED TO ADD UNITS TO A WORK ORDER PLZ DONT DELETE
  def search_units(admin) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    now =
      AppCount.current_time()
      |> Timex.to_date()

    from(
      u in Unit,
      join: p in assoc(u, :property),
      left_join: tenancy in assoc(u, :tenancies),
      on: tenancy.unit_id == u.id and tenancy.start_date <= ^now,
      left_join: tenant in assoc(tenancy, :tenant),
      select: %{
        id: u.id,
        number: u.number,
        property_id: p.id,
        property: p.name,
        tenant_id: tenant.id,
        tenant: fragment("? || ' ' || ?", tenant.first_name, tenant.last_name)
      },
      group_by: [u.id, p.id, tenant.id],
      where: u.property_id in ^property_ids
    )
    |> Repo.all()
  end

  def search_units(admin, term) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    sq =
      from(
        tenancy in AppCount.Tenants.Tenancy,
        join: t in assoc(tenancy, :tenant),
        left_join: acct in assoc(t, :account),
        where: tenancy.start_date <= ^AppCount.current_time() and is_nil(tenancy.actual_move_out),
        select: map(tenancy, [:id, :unit_id]),
        select_merge: %{
          tenant_id: t.id,
          email: t.email,
          phone: t.phone,
          allow_sms: acct.allow_sms
        }
      )

    from(
      u in Unit,
      join: p in assoc(u, :property),
      left_join: t in subquery(sq),
      on: u.id == t.unit_id,
      where: ilike(u.number, ^"%#{term}%"),
      where: u.property_id in ^property_ids,
      select: %{
        id: u.id,
        number: u.number,
        property_id: u.property_id,
        property: p.name,
        tenant_id: t.tenant_id,
        email: t.email,
        allow_sms: t.allow_sms,
        phone: t.phone
      },
      distinct: u.id,
      order_by: [asc: :number]
    )
    |> Repo.all()
  end

  defp set_unit_features(id, feature_ids) do
    from(uf in UnitFeature, where: uf.unit_id == ^id and uf.feature_id not in ^feature_ids)
    |> Repo.delete_all()

    feature_ids
    |> Enum.each(&add_unit_feature(id, &1))
  end

  defp add_unit_feature(id, feature_id) do
    %UnitFeature{}
    |> UnitFeature.changeset(%{unit_id: id, feature_id: feature_id})
    |> Repo.insert()
  end

  def unit_query(admin) do
    charges_query =
      from(
        c in Charge,
        join: cc in assoc(c, :charge_code),
        select: %{
          id: c.id,
          amount: c.amount,
          name: cc.name,
          lease_id: c.lease_id
        }
      )

    lease_query =
      from(
        l in Lease,
        join: tenancy in AppCount.Tenants.Tenancy,
        on: tenancy.customer_ledger_id == l.customer_ledger_id,
        join: t in assoc(tenancy, :tenant),
        left_join: c in subquery(charges_query),
        on: c.lease_id == l.id,
        select: %{
          id: l.id,
          start_date: l.start_date,
          end_date: l.end_date,
          move_out_date: tenancy.expected_move_out,
          expected_move_in: tenancy.expected_move_in,
          actual_move_in: tenancy.actual_move_in,
          unit_id: tenancy.unit_id,
          tenants: jsonize(t, [:id, :first_name, :last_name, {:tenancy_id, tenancy.id}]),
          notice_date: tenancy.notice_date,
          #          deposit_amount: l.deposit_amount,
          actual_move_out: tenancy.actual_move_out,
          #          renewal_id: l.renewal_id,
          charges: jsonize(c, [:id, :amount, :name])
        },
        group_by: [l.id, tenancy.id]
      )

    mr_query =
      from(
        u in Unit,
        left_join: f in assoc(u, :features),
        left_join: plan in assoc(u, :floor_plan),
        left_join: fp in assoc(plan, :features),
        left_join: dc in assoc(plan, :default_charges),
        left_join: cc in assoc(dc, :charge_code),
        where: is_nil(f.stop_date),
        where: is_nil(fp.stop_date),
        select: %{
          id: u.id,
          market_rent: coalesce(f.price, 0) + coalesce(fp.price, 0),
          default_charges:
            jsonize(dc, [:id, :price, :default_charge, {:charge_code, cc.name}, :charge_code_id])
        },
        group_by: [u.id, f.price, fp.price]
      )

    from(
      u in Unit,
      left_join: f in assoc(u, :features),
      left_join: p in assoc(u, :property),
      left_join: s in assoc(p, :setting),
      left_join: l in subquery(lease_query),
      on: l.unit_id == u.id,
      left_join: fp in assoc(u, :floor_plan),
      left_join: mr in subquery(mr_query),
      on: u.id == mr.id,
      where: is_nil(f.stop_date),
      select: %{
        id: u.id,
        property_id: u.property_id,
        property_name: p.name,
        number: u.number,
        area: u.area,
        floor_plan_id: u.floor_plan_id,
        floor_plan: fp.name,
        status: u.status,
        area_rate: s.area_rate,
        default_price: mr.market_rent + s.area_rate * u.area,
        features: jsonize(f, [:id, :name, :price]),
        feature_ids: array(f.id),
        leases: jsonize(l, unquote(@lease_fields)),
        address: u.address,
        default_charges: mr.default_charges
      },
      group_by: [u.id, p.id, s.area_rate, mr.market_rent, mr.default_charges, fp.id],
      where: u.property_id in ^admin.property_ids
    )
  end

  def lease_query(property_id) do
    current_date = AppCount.current_date()
    haprent_cc = AppCount.Accounting.SpecialAccounts.get_charge_code(:hap_rent).id

    AppCount.Tenants.TenancyRepo.property_tenancies_query(property_id)
    |> join(:inner, [tenancy, unit], l in Lease,
      on: l.customer_ledger_id == tenancy.customer_ledger_id
    )
    |> join(:left, [_, _, l], hc in AppCount.Leasing.Charge,
      on:
        l.id == hc.lease_id and hc.charge_code_id == ^haprent_cc and
          (is_nil(hc.to_date) or hc.to_date >= ^current_date) and
          (is_nil(hc.from_date) or hc.from_date <= ^current_date)
    )
    |> join(:inner, [tenancy], t in assoc(tenancy, :tenant))
    |> join(:left, [_, _, l], c in subquery(Queries.rent_charge_query(current_date)),
      on: c.lease_id == l.id
    )
    |> select([tenancy, unit, lease, hap_rent, tenant, rent_charge], %{
      id: tenancy.id,
      unit_id: tenancy.unit_id,
      start_date: tenancy.start_date,
      expected_move_out: tenancy.expected_move_out,
      actual_move_in: tenancy.actual_move_in,
      actual_move_out: tenancy.actual_move_out,
      haprent: not is_nil(hap_rent),
      move_out_date: tenancy.expected_move_out,
      current_rent: coalesce(rent_charge.amount, 0),
      tenants:
        jsonize(tenant, [
          :id,
          {:full_name, fragment("? || ' ' || ?", tenant.first_name, tenant.last_name)}
        ])
    })
    |> group_by([tenancy, unit, lease, haprent, tenant, rent_charge], [
      tenancy.id,
      haprent.id,
      rent_charge.amount
    ])
  end

  def sort_leases(%{leases: []} = u), do: u

  def sort_leases(%{leases: leases} = u) do
    reduced =
      Enum.reduce(leases, %{current_lease: [], future_leases: [], past_leases: []}, fn l, acc ->
        case check_status(l) do
          :current ->
            %{
              current_lease: acc[:current_lease] ++ [l],
              past_leases: acc[:past_leases],
              future_leases: acc[:future_leases]
            }

          :past ->
            %{
              past_leases: acc[:past_leases] ++ [l],
              current_lease: acc[:current_lease],
              future_leases: acc[:future_leases]
            }

          :future ->
            %{
              future_leases: acc[:future_leases] ++ [l],
              current_lease: acc[:current_lease],
              past_leases: acc[:past_leases]
            }

          _ ->
            %{
              future_leases: acc[:future_leases],
              current_lease: acc[:current_lease],
              past_leases: acc[:past_leases]
            }
        end
      end)

    Map.merge(u, reduced)
  end

  defp check_status(%{"start_date" => sd, "actual_move_out" => amo, "actual_move_in" => ami}) do
    today =
      AppCount.current_date()
      |> Timex.format!("{YYYY}-{0M}-{0D}")

    cond do
      sd <= today and (is_nil(amo) or amo >= today) -> :current
      (sd <= today and not is_nil(amo)) or amo <= today -> :past
      sd >= today and (is_nil(ami) or ami >= today) -> :future
      true -> :unknown
    end
  end
end
