defmodule AppCount.Tenants.Utils.TenantData do
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Tenants.Tenant
  alias AppCount.Tenants.Pet
  alias AppCount.Tenants.Vehicle
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.Batch

  import Ecto.Query
  import AppCount.EctoExtensions

  # called only by  AppCountWeb.API.TenantController.show()
  def get_tenant(admin, id) do
    from(
      t in Tenant,
      join: l in subquery(lease_query(admin, id)),
      on: l.tenant_id == t.id,
      left_join: v in assoc(t, :visits),
      left_join: p in subquery(pets(id)),
      on: p.tenant_id == t.id,
      left_join: ve in subquery(vehicles(id)),
      on: ve.tenant_id == t.id,
      left_join: app in assoc(t, :application),
      left_join: memo in assoc(app, :memos),
      left_join: admin in assoc(memo, :admin),
      select:
        map(
          t,
          [
            :id,
            :email,
            :first_name,
            :last_name,
            :payment_status,
            :phone,
            :alarm_code,
            :application_id,
            :external_id
          ]
        ),
      select_merge: %{
        visits: jsonize(v, [:id, :description, :admin, :delinquency, :inserted_at]),
        vehicles: coalesce(ve.vehicles, "[]"),
        pets: coalesce(p.pets, "[]"),
        application_memos:
          jsonize(memo, [:id, :note, :admin_id, :inserted_at, {:admin_name, admin.name}]),
        leases:
          jsonize(
            l,
            [
              :id,
              :tenants,
              :renewal,
              :start_date,
              :end_date,
              :move_out_date,
              :expected_move_in,
              :actual_move_in,
              :actual_move_out,
              :move_out_reason_id,
              :notice_date,
              :deposit_amount,
              :charges,
              :unit,
              :property,
              :is_current,
              :eviction,
              :occupants,
              :screenings,
              :closed,
              :bluemoon_lease_id,
              :pending_bluemoon_lease_id,
              :payments,
              :bills,
              :no_renewal
            ]
          )
      },
      where: t.id == ^id,
      group_by: [t.id, ve.vehicles, p.pets]
    )
    |> Repo.one(timeout: 300_000)
    |> put_invalid_email_flag()
    |> Map.merge(%{
      documents: AppCount.Properties.Utils.Documents.list_documents(id),
      emails: AppCount.Messaging.Utils.Emails.list_emails(id)
    })
  end

  def put_invalid_email_flag(%{email: email} = tenant) do
    Map.merge(
      tenant,
      %{
        invalid_email: tenant_email_invalid?(email)
      }
    )
  end

  # Fallback for anything that doesn't match above
  def put_invalid_email_flag(args) do
    args
  end

  @doc """
  Is our tenant email in the bounced list? We can compose other validation
  checks at will
  """
  def tenant_email_invalid?(email) do
    AppCount.Messaging.BounceRepo.exists?(email)
  end

  # Enter tenant_id and get: rent amount,
  def basic_tenant_info(tenant_id, unit_id) do
    rent_query =
      from(
        c in AppCount.Properties.Charge,
        join: cc in assoc(c, :charge_code),
        join: a in assoc(cc, :account),
        join: l in assoc(c, :lease),
        where: a.name == "Rent" or (a.name == "HAP Rent" and l.unit_id == ^unit_id),
        select: %{
          id: c.lease_id,
          amount: sum(c.amount)
        },
        group_by: [c.lease_id]
      )

    from(
      t in Tenant,
      join: l in assoc(t, :leases),
      left_join: e in assoc(l, :eviction),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      left_join: r in subquery(rent_query),
      on: r.id == l.id,
      where: t.id == ^tenant_id and l.unit_id == ^unit_id,
      select: %{
        id: t.id,
        name: fragment("? || ' ' || ?", t.first_name, t.last_name),
        property: p.name,
        email: t.email,
        phone: t.phone,
        lease_start: l.start_date,
        lease_end: l.end_date,
        move_in: l.actual_move_in,
        move_out: l.actual_move_out,
        status:
          fragment(
            "CASE
            WHEN ? IS NOT NULL AND ? IS NULL THEN 'Under Eviction'
            WHEN ? IS NOT NULL THEN 'Past'
            WHEN ? IS NOT NULL THEN 'On Notice'
            WHEN ? IS NOT NULL THEN 'Current'
            ELSE 'future'
          END",
            e.id,
            # eviction when
            l.actual_move_out,
            # eviction when
            l.actual_move_out,
            # moved out when
            l.notice_date,
            # notice when
            l.actual_move_in
            # current when
          ),
        rent: r.amount
      },
      order_by: [
        desc: l.end_date
      ],
      limit: 1
    )
    |> Repo.one()
  end

  defp vehicles(id) do
    from(
      v in Vehicle,
      where: v.tenant_id == ^id,
      select: %{
        tenant_id: v.tenant_id,
        vehicles: jsonize(v, [:id, :make_model, :color, :state, :license_plate, :active])
      },
      group_by: v.tenant_id
    )
  end

  defp pets(id) do
    from(
      p in Pet,
      where: p.tenant_id == ^id,
      select: %{
        tenant_id: p.tenant_id,
        pets: jsonize(p, [:id, :type, :breed, :weight, :name, :active])
      },
      group_by: p.tenant_id
    )
  end

  defp lease_query(admin, id) do
    now =
      AppCount.current_time()
      |> Timex.to_date()

    lease_ids =
      from(
        t in Tenant,
        join: o in assoc(t, :occupancies),
        where: t.id == ^id,
        select: array(o.lease_id)
      )
      |> Repo.one()

    batch_query =
      from(
        b in Batch,
        select: %{
          id: b.id,
          memo: b.memo
        }
      )

    from(
      l in Lease,
      join: o in assoc(l, :occupancies),
      join: t in assoc(o, :tenant),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      left_join: pmt in assoc(l, :payments),
      left_join: ps in assoc(pmt, :payment_source),
      left_join: b in subquery(batch_query),
      on: b.id == pmt.batch_id,
      left_join: c in assoc(l, :charges),
      left_join: cc in assoc(c, :charge_code),
      #      left_join: a in assoc(c, :account),
      left_join: bill in assoc(l, :bills),
      left_join: ch in assoc(bill, :charge_code),
      left_join: rev in assoc(bill, :reversed),
      left_join: e in assoc(l, :eviction),
      left_join: r in assoc(l, :renewal),
      left_join: s in assoc(p, :setting),
      left_join: scr in assoc(l, :screenings),
      left_join: occupants in assoc(l, :occupants),
      select:
        map(
          l,
          [
            :id,
            :unit_id,
            :move_out_reason_id,
            :start_date,
            :end_date,
            :move_out_date,
            :expected_move_in,
            :actual_move_in,
            :actual_move_out,
            :notice_date,
            :deposit_amount,
            :closed,
            :bluemoon_lease_id,
            :pending_bluemoon_lease_id,
            :no_renewal
          ]
        ),
      select_merge: %{
        tenant_id: filter(max(o.tenant_id), o.tenant_id == ^id),
        tenant_ids: array(o.tenant_id),
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        screenings: jsonize(scr, [:id, :first_name, :last_name, :status, :decision, :url]),
        renewal: jsonize_one(r, [:id, :start_date]),
        eviction: jsonize_one(e, [:id, :file_date, :court_date, :notes]),
        charges:
          jsonize(c, [
            :id,
            :amount,
            {:charge_code, cc.code},
            :charge_code_id,
            :from_date,
            :to_date,
            :next_bill_date
          ]),
        bills:
          jsonize(
            bill,
            [
              :id,
              {:charge_code, ch.code},
              :amount,
              {:reversed_date, rev.bill_date},
              :description,
              :reversal_id,
              :bill_date,
              :status,
              :inserted_at,
              :post_month,
              :admin,
              :image_id,
              :nsf_id
            ]
          ),
        unit: jsonize_one(u, [:id, :number]),
        property:
          jsonize_one(p, [
            :id,
            :name,
            :address,
            {:notice_period, s.notice_period},
            {:integration, s.integration},
            {:sync_ledgers, s.sync_ledgers}
          ]),
        is_current:
          l.start_date <= ^now and is_nil(l.actual_move_out) and
            (l.end_date > ^now or is_nil(l.renewal_id)),
        occupants: jsonize(occupants, schema_fields(Properties.Occupant)),
        payments:
          jsonize(
            pmt,
            [
              :id,
              :description,
              :amount,
              :surcharge,
              :transaction_id,
              :inserted_at,
              :image_id,
              :status,
              :source,
              :admin,
              :post_month,
              :property_id,
              :lease_id,
              :post_error,
              {:type, ps.type},
              {:memo, b.memo}
            ]
          )
      },
      where: p.id in ^admin.property_ids,
      where: l.id in ^lease_ids,
      group_by: [l.id, p.id]
    )
  end
end
