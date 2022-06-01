defmodule AppCount.Reports.AdminPaymentsAndCharges do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Ledgers.Charge
  alias AppCount.Ledgers.Payment

  def index(admin_id, start_date, end_date) do
    admin_name = Repo.get(AppCount.Admins.Admin, admin_id).name

    #    weird behaviour of union. if it's not in a variable, all results would have the type of "payment".
    charge = "charge"
    payment = "payment"
    account = "account"

    payments =
      from(
        p in Payment,
        join: t in assoc(p, :tenant),
        select: map(p, [:id, :description, :inserted_at]),
        select_merge: %{
          amount: type(p.amount, :float),
          tenant_id: t.id,
          tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
          type: ^payment,
          account: ^account
        },
        where: p.admin == ^admin_name,
        where: p.inserted_at >= ^start_date and p.inserted_at <= ^end_date
      )

    charges =
      from(
        c in Charge,
        join: l in assoc(c, :lease),
        join: t in assoc(l, :tenants),
        join: a in assoc(c, :account),
        select: map(c, [:id, :description, :inserted_at]),
        select_merge: %{
          amount: type(c.amount, :float),
          tenant_id: t.id,
          tenant: fragment("? || ' ' || ?", t.first_name, t.last_name),
          type: ^charge,
          account: a.name
        },
        where: c.inserted_at >= ^start_date and c.inserted_at <= ^end_date,
        where: c.admin == ^admin_name
      )

    query = union(payments, ^charges)

    from(q in subquery(query), order_by: q.inserted_at)
    |> Repo.all()
  end
end
