defmodule AppCount.Leasing.Utils.RenewalPeriods do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Properties
  alias AppCount.Tenants
  alias AppCount.Leasing.RenewalPeriod
  alias AppCount.Leasing.RenewalPackage
  alias AppCount.Leasing.CustomPackage
  alias AppCount.Leasing.Lease
  require Logger
  alias AppCount.Core.ClientSchema

  def create_renewal_period(%ClientSchema{
        name: client_schema,
        attrs: %{"packages" => packages} = params
      }) do
    %RenewalPeriod{}
    |> RenewalPeriod.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> create_packages(%ClientSchema{
      name: client_schema,
      attrs: packages
    })
  end

  def notify_regional(%{client_schema: _client_schema} = admin, period_id) do
    renewal_period = Repo.get(RenewalPeriod, period_id, prefix: admin.client_schema)

    property =
      Properties.get_property(ClientSchema.new(admin.client_schema, renewal_period.property_id))

    regionals =
      Admins.admins_for(
        ClientSchema.new(admin.client_schema, property.id),
        ["Regional"]
      )

    Enum.each(
      regionals,
      &AppCountCom.RenewalApprovalRequest.renewal_approval_request(
        property,
        &1,
        admin,
        renewal_period
      )
    )

    {:ok, nil}
  end

  @doc """
   Required in case %AppCount.Admins.Admin{} is passed instead of Admin Auth Struct
  """
  def notify_regional(%AppCount.Admins.Admin{} = admin, period_id) do
    admin
    |> Map.put(:client_schema, admin.__meta__.prefix)
    |> notify_regional(period_id)
  end

  def approve_renewal_period(%ClientSchema{name: client_schema, attrs: admin}, id) do
    unless Map.take(admin.roles.map, ["Super Admin", "Regional"]) == %{} do
      params = %{approval_date: AppCount.current_date(), approval_admin: admin.name}

      Repo.get(RenewalPeriod, id, prefix: client_schema)
      |> RenewalPeriod.changeset(params)
      |> Repo.update(prefix: client_schema)
    end
  end

  def update_renewal_period(
        %ClientSchema{name: client_schema, attrs: id},
        %{"packages" => packages} = params
      ) do
    package_ids =
      Enum.map(packages, & &1["id"])
      |> Enum.filter(& &1)

    from(p in RenewalPackage, where: p.renewal_period_id == ^id and p.id not in ^package_ids)
    |> Repo.delete_all(prefix: client_schema)

    Enum.each(
      packages,
      fn package ->
        if package["id"] do
          Repo.get(RenewalPackage, package["id"], prefix: client_schema)
          |> RenewalPackage.changeset(package)
          |> Repo.update(prefix: client_schema)
        else
          %RenewalPackage{}
          |> RenewalPackage.changeset(Map.put(package, "renewal_period_id", id))
          |> Repo.insert(prefix: client_schema)
        end
      end
    )

    Repo.get(RenewalPeriod, id, prefix: client_schema)
    |> RenewalPeriod.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def add_note(%ClientSchema{name: client_schema, attrs: id}, text, admin) do
    pack = Repo.get(RenewalPeriod, id, prefix: client_schema)

    notes =
      pack.notes ++ [%{"text" => text, "admin" => admin.name, "time" => AppCount.current_time()}]

    pack
    |> RenewalPeriod.changeset(%{notes: notes})
    |> Repo.update(prefix: client_schema)
  end

  def delete_renewal_period(%ClientSchema{name: client_schema, attrs: id}) do
    case can_delete(id) do
      true -> truly_delete_renewal_period(%ClientSchema{name: client_schema, attrs: id})
      false -> {:error, "Unable to delete"}
    end
  end

  def print_period_letters(id) do
    string = "#{id}_%_Renewal_Offer"

    from(
      d in AppCount.Properties.Document,
      join: u in assoc(d, :document_url),
      where: ilike(d.name, ^string),
      select: u.url,
      order_by: [
        desc: :inserted_at
      ]
    )
    |> AppCount.Data.concatenate_pdfs()
  end

  def notify_pm_renewal(
        %ClientSchema{name: client_schema, attrs: lease_id},
        tenant_id,
        package_id
      ) do
    renewal =
      from(
        p in RenewalPackage,
        left_join: cp in CustomPackage,
        on: cp.lease_id == ^lease_id,
        join: rp in assoc(p, :renewal_period),
        where: p.id == ^package_id,
        select: %{
          property_id: rp.property_id,
          package: map(p, [:id, :min, :max, :renewal_period_id, :amount, :base, :dollar]),
          custom_package: map(cp, [:amount, :lease_id, :renewal_package_id])
        }
      )
      |> Repo.one(prefix: client_schema)
      |> parse_package

    ClientSchema.new(client_schema, renewal)
    |> send_email(lease_id, tenant_id)
  end

  def send_email(
        %ClientSchema{name: client_schema, attrs: package},
        lease_id,
        tenant_id
      ) do
    property = Properties.get_property(ClientSchema.new(client_schema, package.property_id))

    resident = Repo.get(AppCount.Tenants.Tenant, tenant_id, prefix: client_schema)

    Enum.each(
      Admins.admins_for(ClientSchema.new(client_schema, package.property_id), ["Admin"]),
      fn manager ->
        AppCount.Core.Tasker.start(fn ->
          AppCountCom.RenewalApprovalRequest.notify_pm_approval(
            manager,
            resident,
            property,
            package,
            lease_id
          )
        end)
      end
    )
  end

  def parse_package(%{package: package, property_id: property_id, custom_package: nil}) do
    %{
      amount: package.amount,
      base: package.base,
      dollar: package.dollar,
      id: package.id,
      min: package.min,
      max: package.max,
      property_id: property_id,
      custom_package: false
    }
  end

  def parse_package(%{package: package, property_id: property_id, custom_package: custom_package}) do
    %{
      amount: custom_package.amount,
      base: package.base,
      dollar: package.dollar,
      id: package.id,
      min: package.min,
      max: package.max,
      property_id: property_id,
      custom_package: true
    }
  end

  def find_lease_packages(%ClientSchema{name: client_schema, attrs: user_id}) do
    from(
      t in Tenants.Tenant,
      join: te in assoc(t, :tenancies),
      join: lease in assoc(te, :leases),
      join: u in assoc(te, :unit),
      select: %{
        lease_id: lease.id,
        property_id: u.property_id
      },
      distinct: lease.customer_ledger_id,
      order_by: [desc: lease.start_date],
      where: t.id == ^user_id,
      where: is_nil(te.actual_move_out)
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.reduce([], fn x, acc ->
      renewal_query(x.property_id, x.lease_id)
      |> where([renewal: r], not is_nil(r.approver))
      |> Repo.one(prefix: client_schema)
      |> case do
        nil -> acc
        renewal -> acc ++ [renewal]
      end
    end)
  end

  def find_lease_packages(%ClientSchema{name: client_schema, attrs: admin}, property_id, lease_id) do
    case Admins.has_permission?(%ClientSchema{name: client_schema, attrs: admin}, property_id) do
      true -> find_lease_packages(ClientSchema.new(client_schema, property_id), lease_id)
      _ -> "Insufficient Permissions"
    end
  end

  defp renewal_query(property_id, lease_id) do
    mr_sub = mr_sub()

    renewal_period =
      from(
        p in RenewalPeriod,
        join: pack in assoc(p, :packages),
        left_join: cp in assoc(pack, :custom_packages),
        on: cp.lease_id == ^lease_id,
        left_join: settings in AppCount.Properties.Setting,
        select: %{
          threshold: settings.renewal_overage_threshold,
          packages:
            jsonize(pack, [:id, :min, :max, :amount, :base, :dollar, :renewal_period_id, :notes]),
          custom_packages:
            jsonize(cp, [
              :id,
              :amount,
              :renewal_package_id,
              :notes,
              :lease_id,
              {:min, pack.min},
              {:max, pack.max}
            ]),
          start_date: p.start_date,
          end_date: p.end_date,
          id: p.id,
          approver: p.approval_admin
        },
        group_by: [p.id, settings.id],
        where: p.property_id == ^property_id
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: te in assoc(l, :tenancies),
      left_join: mr in subquery(mr_sub),
      on: u.id == mr.unit_id,
      left_join: r in subquery(renewal_period),
      as: :renewal,
      on: l.end_date >= r.start_date and l.end_date <= r.end_date,
      left_join: c in assoc(l, :charges),
      left_join: cc in assoc(c, :charge_code),
      left_join: fp in assoc(u, :floor_plan),
      left_join: dfl in assoc(fp, :default_charges),
      left_join: ccc in assoc(dfl, :charge_code),
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        unit: u.number,
        unit_id: u.id,
        market_rent: mr.market_rent,
        fp_id: fp.id,
        packages: r.packages,
        charges: jsonize(c, [:id, :amount, :to_date, {:charge_code, ccc.name}]),
        default_lease_charges:
          jsonize(dfl, [:id, :price, :default_charge, :charge_code_id, {:charge_code, ccc.name}]),
        custom_packages: r.custom_packages
      },
      distinct: l.customer_ledger_id,
      order_by: [desc: l.start_date],
      group_by: [l.id, u.id, mr.market_rent, r.id, fp.id, r.packages, r.custom_packages],
      where:
        is_nil(te.actual_move_out) and is_nil(te.notice_date) and l.id == ^lease_id and
          is_nil(l.renewal_package_id)
    )
  end

  def find_lease_packages(%ClientSchema{name: client_schema, attrs: property_id}, lease_id) do
    renewal_query(property_id, lease_id)
    |> Repo.one(prefix: client_schema)
  end

  def list_renewal_periods(admin, property_id) do
    case Admins.has_permission?(ClientSchema.new(admin), property_id) do
      true -> list_renewal_periods(ClientSchema.new(admin.client_schema, property_id))
      _ -> "Insufficient Permissions"
    end
  end

  defp mr_sub do
    from(
      u in AppCount.Properties.Unit,
      left_join: f in assoc(u, :features),
      left_join: plan in assoc(u, :floor_plan),
      left_join: fp in assoc(plan, :features),
      where: is_nil(f.stop_date),
      where: is_nil(fp.stop_date),
      select: %{
        unit_id: u.id,
        market_rent: coalesce(f.price, 0) + coalesce(fp.price, 0)
      },
      group_by: [u.id, f.price, fp.price]
    )
  end

  defp list_renewal_periods(%ClientSchema{name: client_schema, attrs: property_id}) do
    mr_sub = mr_sub()

    leases =
      from(
        l in Lease,
        join: u in assoc(l, :unit),
        left_join: mr in subquery(mr_sub),
        on: u.id == mr.unit_id,
        join: c in assoc(l, :charges),
        join: cc in assoc(c, :charge_code),
        join: tenancy in AppCount.Tenants.Tenancy,
        on: tenancy.customer_ledger_id == l.customer_ledger_id,
        join: t in assoc(tenancy, :tenant),
        where:
          is_nil(tenancy.actual_move_out) and is_nil(tenancy.notice_date) and
            u.property_id == ^property_id and
            is_nil(l.renewal_package_id),
        where: l.no_renewal == false,
        select: %{
          id: l.id,
          unit: u.number,
          start_date: l.start_date,
          end_date: l.end_date,
          no_renewal: l.no_renewal,
          market_rent: mr.market_rent,
          charges: jsonize(c, [:id, :amount, :to_date, {:account, cc.name}]),
          tenants:
            jsonize(t, [:id, {:name, fragment("? || ' ' || ?", t.first_name, t.last_name)}])
        },
        order_by: [
          asc: u.number,
          desc: l.start_date
        ],
        distinct: l.customer_ledger_id,
        group_by: [l.id, u.id, mr.market_rent]
      )

    packages =
      from(
        p in RenewalPackage,
        left_join: cp in assoc(p, :custom_packages),
        select: map(p, [:id, :min, :max, :base, :amount, :dollar, :notes, :renewal_period_id]),
        select_merge: %{
          custom_packages: jsonize(cp, [:id, :amount, :notes, :lease_id])
        },
        group_by: p.id
      )

    from(
      p in RenewalPeriod,
      left_join: pack in subquery(packages),
      on: pack.renewal_period_id == p.id,
      left_join: l in subquery(leases),
      on: l.end_date >= p.start_date and l.end_date <= p.end_date,
      left_join: settings in AppCount.Properties.Setting,
      on: settings.property_id == p.property_id,
      where: p.property_id == ^property_id,
      select:
        map(p, [:id, :creator, :approval_date, :approval_admin, :start_date, :end_date, :notes]),
      select_merge: %{
        threshold: settings.renewal_overage_threshold,
        packages:
          jsonize(pack, [:id, :min, :max, :base, :amount, :dollar, :notes, :custom_packages]),
        leases:
          jsonize(
            l,
            [
              :id,
              :unit,
              :tenants,
              :charges,
              :market_rent,
              :start_date,
              :end_date
            ]
          )
      },
      group_by: [p.id, settings.id],
      order_by: [
        asc: p.start_date
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def check_if_valid_period(
        %ClientSchema{name: client_schema, attrs: property_id},
        start_date,
        end_date
      ) do
    from(
      p in RenewalPeriod,
      where: p.property_id == ^property_id,
      where:
        fragment(
          "(?, ? + 1) OVERLAPS (?, ? + 1)",
          p.start_date,
          p.end_date,
          type(^start_date, :date),
          type(^end_date, :date)
        ),
      select: count(p.id)
    )
    |> Repo.one(prefix: client_schema)
    |> Kernel.==(0)
    |> if do
      count =
        from(
          l in Lease,
          join: u in assoc(l, :unit),
          where: u.property_id == ^property_id,
          where: between(l.end_date, type(^start_date, :date), type(^end_date, :date)),
          select: count(l.id)
        )
        |> Repo.one(prefix: client_schema)

      %{valid: true, leases: count}
    else
      %{valid: false, leases: 0}
    end
  end

  defp create_packages({:error, e}, _), do: Logger.error(inspect(e))

  defp create_packages({:ok, renewal_period}, %ClientSchema{
         name: client_schema,
         attrs: packages
       }) do
    Enum.each(
      packages,
      fn pack ->
        client_schema
        |> ClientSchema.new(Map.merge(pack, %{"renewal_period_id" => renewal_period.id}))
        |> AppCount.Leasing.Utils.RenewalPackages.create_renewal_package()
      end
    )

    {:ok, renewal_period}
  end

  defp get_leases(%ClientSchema{
         name: client_schema,
         attrs: %{property_id: property_id, start_date: start_date, end_date: end_date}
       }) do
    mr_sub =
      from(
        u in AppCount.Properties.Unit,
        left_join: f in assoc(u, :features),
        left_join: plan in assoc(u, :floor_plan),
        left_join: fp in assoc(plan, :features),
        where: is_nil(f.stop_date),
        where: is_nil(fp.stop_date),
        select: %{
          unit_id: u.id,
          market_rent: coalesce(f.price, 0) + coalesce(fp.price, 0)
        },
        group_by: [u.id, f.price, fp.price]
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      left_join: mr in subquery(mr_sub),
      on: u.id == mr.unit_id,
      join: c in assoc(l, :charges),
      join: a in assoc(c, :account),
      join: t in assoc(l, :tenants),
      left_join: cp in assoc(l, :custom_packages),
      where:
        is_nil(l.actual_move_out) and is_nil(l.notice_date) and u.property_id == ^property_id and
          is_nil(l.renewal_package_id) and is_nil(l.renewal_id),
      where: l.end_date <= ^end_date and l.end_date >= ^start_date,
      select: %{
        id: l.id,
        unit: u.number,
        start_date: l.start_date,
        end_date: l.end_date,
        market_rent: mr.market_rent,
        charges: jsonize(c, [:id, :amount, :to_date, {:account, a.name}]),
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        custom_packages:
          jsonize(cp, [:id, :amount, :min, :max, :notes, :lease_id, :renewal_period_id])
      },
      order_by: [
        asc: u.number
      ],
      group_by: [l.id, u.id, mr.market_rent]
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_leases(params, :total) do
    get_leases(params)
    |> length
  end

  defp truly_delete_renewal_period(%ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(RenewalPeriod, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  ## THIS FUNCTION WILL GO THROUGH ALL THE RENEWAL PACKAGES WITH THE GIVEN ID AND IF ONE OF THEM HAS BEEN SELECTED IT WILL RETURN FALSE
  defp can_delete(_) do
    true
  end
end
