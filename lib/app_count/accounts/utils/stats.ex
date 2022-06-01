defmodule AppCount.Accounts.Utils.Stats do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Accounts.Login
  alias AppCount.Accounts.PaymentSource
  alias AppCount.Accounts.Payment
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Charge
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Assignment
  alias AppCount.RentApply.RentApplication
  alias AppCount.Prospects.Showing
  alias AppCount.Prospects.Prospect
  alias AppCount.Properties.Package
  alias AppCount.Admins
  alias AppCount.Maintenance.Utils.Reports
  alias AppCount.Core.Clock
  alias AppCount.Core.ClientSchema

  def admin_stats(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        property_ids,
        start_date \\ nil,
        end_date \\ nil
      ) do
    property_ids = property_ids || Admins.property_ids_for(ClientSchema.new(client_schema, admin))

    end_d = end_date || Clock.today() |> Clock.eod()

    start_d = start_date || Timex.shift(end_d, days: -30)

    %{
      logins: logins(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      payment_sources:
        payment_sources(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      payments: tenant_payments(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      work_orders: work_orders(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      collections: collections(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      work_orders_completed:
        completed_work_orders(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      applications: applications(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      in_house_applications:
        in_house_applications(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      showings: showings(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      prospects: prospects(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      packages: packages(start_d, end_d, ClientSchema.new(client_schema, property_ids)),
      maint_history:
        Reports.property_stats_query_by_admin_dates(
          ClientSchema.new(client_schema, admin),
          start_d,
          end_d
        )
    }
  end

  def logins(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      l in Login,
      join: a in assoc(l, :account),
      where:
        l.inserted_at <= ^end_date and l.inserted_at >= ^start_date and
          a.property_id in ^property_ids,
      select: count(l.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def payment_sources(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      p in PaymentSource,
      join: a in assoc(p, :account),
      where:
        p.inserted_at <= ^end_date and p.inserted_at >= ^start_date and
          a.property_id in ^property_ids,
      select: count(p.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def collections(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      c in Charge,
      left_join: r in assoc(c, :receipts),
      left_join: p in assoc(r, :payment),
      on: p.id == r.payment_id and is_nil(r.stop_date),
      join: l in assoc(c, :lease),
      join: u in assoc(l, :unit),
      where:
        p.inserted_at <= ^end_date and p.inserted_at >= ^start_date and
          u.property_id in ^property_ids,
      select: %{
        collected: sum(r.amount),
        surcharges: sum(p.surcharge),
        outstanding: sum(c.amount) - sum(r.amount)
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  def tenant_payments(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      p in Payment,
      where: p.inserted_at <= ^end_date and p.inserted_at >= ^start_date,
      where: p.property_id in ^property_ids,
      select: %{
        admin: count(fragment("CASE WHEN ? = 'admin' THEN 1 END", p.source)),
        web: count(fragment("CASE WHEN ? = 'web' OR ? = 'site' THEN 1 END", p.source, p.source)),
        app: count(fragment("CASE WHEN ? = 'app' THEN 1 END", p.source)),
        collected: sum(p.amount),
        surcharges: sum(p.surcharge),
        surcharge_count: count(fragment("CASE WHEN ? > 0 THEN 1 END", p.surcharge))
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  def work_orders(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      o in Order,
      where:
        o.inserted_at <= ^end_date and o.inserted_at >= ^start_date and
          o.property_id in ^property_ids,
      select: count(o.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def completed_work_orders(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      a in Assignment,
      join: o in assoc(a, :order),
      where:
        a.status == "completed" and a.completed_at <= ^end_date and a.completed_at >= ^start_date and
          o.property_id in ^property_ids,
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def applications(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      a in RentApplication,
      where:
        a.inserted_at <= ^end_date and a.inserted_at >= ^start_date and
          a.property_id in ^property_ids,
      where: is_nil(a.device_id),
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def in_house_applications(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      a in RentApplication,
      where:
        a.inserted_at <= ^end_date and a.inserted_at >= ^start_date and
          a.property_id in ^property_ids,
      where: not is_nil(a.device_id),
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def showings(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      s in Showing,
      where: s.date <= ^end_date and s.date >= ^start_date and s.property_id in ^property_ids,
      select: count(s.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def prospects(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      p in Prospect,
      where:
        p.inserted_at <= ^end_date and p.inserted_at >= ^start_date and
          p.property_id in ^property_ids,
      select: count(p.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def packages(start_date, end_date, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    from(
      p in Package,
      join: u in assoc(p, :unit),
      where:
        (p.inserted_at <= ^end_date and p.inserted_at >= ^start_date) or
          (p.updated_at <= ^end_date and p.updated_at >= ^start_date and
             u.property_id in ^property_ids),
      select: %{
        id: p.id,
        status: p.status,
        inserted_at: p.inserted_at
      }
    )
    |> Repo.all(prefix: client_schema)
  end
end
