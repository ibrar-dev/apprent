defmodule AppCount.Tasks.Workers.MoneyGramReport do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Ledgers.Payment
  use AppCount.Tasks.Worker, "MoneyGram report"
  alias AppCount.Core.ClientSchema

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    property_payments = get_property_payments()

    from(
      a in AppCount.Admins.Admin,
      where: fragment("? && ?", ^["Accountant"], a.roles)
    )
    |> Repo.all(prefix: schema)
    |> Enum.map(fn admin ->
      %{
        admin: admin,
        properties: Admins.property_ids_for(ClientSchema.new(schema, admin))
      }
    end)
    |> Enum.filter(fn admin ->
      Enum.find(property_payments, fn p -> Enum.member?(admin.properties, p.property_id) end) !=
        nil
    end)
    |> Enum.each(fn admin ->
      Enum.filter(property_payments, fn p -> Enum.member?(admin.properties, p.property_id) end)
      |> send_email(admin.admin)
    end)
  end

  def send_email(payments, admin) do
    AppCount.Core.Tasker.start(fn ->
      AppCountCom.MoneyGram.daily_money_gram_payments(admin, payments)
    end)

    :ok
  end

  def get_property_payments() do
    twenty_four_hours =
      AppCount.current_time()
      |> Timex.shift(hours: -24)

    payments =
      from(
        p in Payment,
        left_join: t in assoc(p, :tenant),
        left_join: pr in assoc(p, :property),
        left_join: l in assoc(t, :leases),
        left_join: u in assoc(l, :unit),
        join: batch in assoc(p, :batch),
        select:
          map(
            p,
            [
              :id,
              :property_id,
              :tenant_id
            ]
          ),
        select_merge: %{
          tenant_name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          unit: u.number,
          property_name: pr.name,
          inserted_at: p.inserted_at,
          amount: type(p.amount, :float)
        },
        where: p.source == "moneygram" and p.inserted_at >= ^twenty_four_hours,
        order_by: [
          asc: :inserted_at
        ]
      )

    from(
      p in AppCount.Properties.Property,
      join: payment in subquery(payments),
      on: p.id == payment.property_id,
      select: %{
        property: p.name,
        payments: jsonize(payment, [:tenant_name, :amount]),
        property_id: p.id
      },
      group_by: [p.name, p.id]
    )
    |> Repo.all()
  end
end
