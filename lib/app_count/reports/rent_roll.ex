defmodule AppCount.Reports.RentRoll do
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.Decimal
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Properties.Unit
  alias AppCount.Leases.Lease
  alias AppCount.RentApply.MoveIn
  alias AppCount.RentApply.Person
  alias AppCount.Core.ClientSchema

  ## PLEASE PLEASE DO NOT MAKE ANY CHANGES OR ADJUSTMENTS TO THIS REPORT!!
  ## THE RENT ROLL REAL HAS BEEN AUDITED AND APPROVED BY FORCES WHO ARE NOT DEVELOPERS!
  ## NO CHANGES WITHOUT SPEAKING TO DAVID ASTOR!

  def rent_roll(admin, property_id, date \\ nil) do
    # TODO:SCHEMA remove dasmen
    if Admins.has_permission?(ClientSchema.new("dasmen", admin), property_id) do
      new_date =
        if(date, do: Timex.parse!(date, "{YYYY}-{0M}-{D}"), else: AppCount.current_time())
        |> Timex.end_of_day()

      rent_roll_real = rent_roll_real(property_id, new_date)
      rent_roll_potent = rent_roll_potent(property_id, new_date)

      charges_summary =
        charges_summary(rent_roll_real, rent_roll_potent)
        |> reduced_charges

      %{
        "rent_roll_real" => rent_roll_real,
        "rent_roll_potent" => rent_roll_potent,
        "charges_summary" => charges_summary,
        "totals" => %{
          "real" => total_real(rent_roll_real),
          "potent" => total_potent(rent_roll_potent),
          "charges" => Enum.reduce(charges_summary, 0, &(&2 + &1.total))
        }
      }
    end
  end

  def rent_roll_real(property_id, date) do
    start_of_month = Timex.beginning_of_month(date)
    account = late_fee_account()

    mr_query =
      from(
        u in Unit,
        left_join: f in assoc(u, :features),
        left_join: plan in assoc(u, :floor_plan),
        left_join: fp in assoc(plan, :features),
        where: is_nil(f.stop_date),
        where: is_nil(fp.stop_date),
        select: %{
          id: u.id,
          market_rent: coalesce(f.price, 0) + coalesce(fp.price, 0)
        }
      )

    # TODO return query based on property__setting.sync_ledgers
    # AppCount.Tenants.ledger_query(property_id: property_id)
    # |> where([c], c.date <= ^date)
    balance_query =
      AppCount.Ledgers.CustomerLedgerRepo.ledger_balances_query()
      |> select(
        [ledgers, payment, charge],
        %{
          ledger_id: ledgers.id,
          balance: coalesce(charge.sum, 0) - coalesce(payment.sum, 0)
        }
      )

    months_late_fees =
      AppCount.Tenants.ledger_query(property_id: property_id)
      |> where(
        [c],
        c.date >= ^start_of_month and c.type == "charge" and c.account == ^account.name
      )

    from(
      u in Unit,
      left_join: mr in subquery(mr_query),
      on: mr.id == u.id,
      left_join: fp in assoc(u, :floor_plan),
      left_join: l in subquery(lease_query(date)),
      on: l.unit_id == u.id,
      left_join: b in subquery(balance_query),
      # on: fragment("? = ? AND ? = ?", b.tenant_id, l.tenant_id, l.unit_id, u.id),
      on: b.ledger_id == l.id,
      left_join: mlf in subquery(months_late_fees),
      on: fragment("? = ? AND ? = ?", mlf.tenant_id, l.tenant_id, l.unit_id, u.id),
      where: u.property_id == ^property_id,
      select: l,
      select_merge: %{
        id: u.id,
        lease_id: l.id,
        number: u.number,
        market_rent: mr.market_rent,
        floor_plan: fp.name,
        sq_footage: u.area,
        balance: b.balance,
        charges: coalesce(l.charges, fragment("'[]'::jsonb"))
      },
      distinct: u.id,
      order_by: [
        asc: u.number,
        desc: l.end_date
      ]
    )
    |> Repo.all()
    |> Enum.map(&check_for_mtm(&1))
    |> Enum.sort(&(&1.number < &2.number))
  end

  def rent_roll_potent(property_id, date) do
    tenants = from(t in AppCount.Tenants.Tenant)

    persons =
      from(
        p in Person,
        join: a in assoc(p, :application),
        on: a.id == p.application_id,
        select: %{
          application_id: a.id,
          id: p.id,
          name: p.full_name
        },
        where: a.property_id == ^property_id
      )

    from(
      m in MoveIn,
      join: p in subquery(persons),
      on: m.application_id == p.application_id,
      join: a in assoc(m, :application),
      left_join: f in assoc(a, :form),
      left_join: fp in assoc(m, :floor_plan),
      left_join: u in assoc(m, :unit),
      left_join: t in subquery(tenants),
      on: a.id == t.application_id,
      left_join: pm in assoc(a, :payments),
      on: pm.application_id == m.application_id,
      left_join: r in assoc(pm, :receipts),
      on:
        pm.id == r.payment_id and (is_nil(r.stop_date) or r.stop_date > ^date) and
          (is_nil(r.start_date) or r.start_date <= ^date),
      left_join: ch in assoc(r, :charge),
      left_join: cc in assoc(ch, :charge_code),
      left_join: acc in assoc(cc, :account),
      left_join: acc2 in assoc(r, :account),
      select: %{
        id: m.id,
        name: p.name,
        unit_id: u.id,
        number: u.number,
        floor_plan: fp.name,
        sq_footage: u.area,
        lease_id: f.id,
        deposit: f.deposit_value,
        application_id: a.id,
        date: m.expected_move_in,
        payments:
          jsonize(pm, [:id, {:amount, r.amount}, {:account, coalesce(acc.name, acc2.name)}]),
        status: a.status
      },
      where: m.expected_move_in <= ^date and a.status != "declined" and is_nil(t.id),
      group_by: [m.id, p.id, u.id, p.name, fp.id, f.id, a.id]
    )
    |> Repo.all()
  end

  def lease_query(date) do
    charge_query =
      from(
        c in AppCount.Properties.Charge,
        join: cc in assoc(c, :charge_code),
        join: a in assoc(cc, :account),
        join: l in assoc(c, :lease),
        where:
          (c.from_date <= ^date and is_nil(c.to_date)) or
            (is_nil(c.from_date) and c.to_date >= ^date) or
            (is_nil(c.from_date) and is_nil(c.to_date)) or
            (c.from_date <= ^date and c.to_date >= ^date),
        select: %{
          id: c.id,
          amount: c.amount,
          account: a.name,
          expired:
            fragment(
              "CASE
        WHEN ? IS NULL AND ? < ? THEN ?
        WHEN ? > ? AND ? < ? THEN ?
        ELSE ?
        END",
              l.actual_move_out,
              l.end_date,
              type(^date, :date),
              true,
              l.actual_move_out,
              type(^date, :date),
              l.end_date,
              type(^date, :date),
              true,
              false
            ),
          lease_id: c.lease_id
        }
      )

    renewal_query =
      from(
        l in Lease,
        where: not is_nil(l.renewal_id),
        select: %{
          id: l.renewal_id,
          deposit_amount: l.deposit_amount
        }
      )

    evictions =
      from(
        t in AppCount.Tenants.Tenant,
        join: l in assoc(t, :leases),
        join: e in assoc(l, :eviction),
        select: %{
          tenant_id: t.id,
          lease_id: l.id,
          eviction_id: e.id,
          file_date: e.file_date,
          court_date: e.court_date
        }
      )

    from(
      l in Lease,
      left_join: t in assoc(l, :tenants),
      left_join: c in subquery(charge_query),
      on: l.id == c.lease_id,
      left_join: r in subquery(renewal_query),
      on: r.id == l.id,
      left_join: e in subquery(evictions),
      on: t.id == e.tenant_id,
      left_join: ren in assoc(l, :renewal),
      #      where: is_nil(e.tenant_id) or is_nil(e.court_date) or e.court_date > ^date,
      where: is_nil(l.actual_move_out) or l.actual_move_out >= ^date,
      where: not is_nil(l.actual_move_in) and l.actual_move_in <= ^date,
      where: is_nil(ren) or (is_nil(ren.actual_move_out) or ren.actual_move_out >= ^date),
      #      where: not is_nil(l.actual_move_in) and l.actual_move_in <= ^date or fragment("? IS NOT NULL AND ? <= ? AND ? IS NULL OR ? >= ?", l.renewal_id, ren.actual_move_in, type(^date, :date), ren.actual_move_out, ren.actual_move_out, type(^date, :date)),
      select: map(l, [:id, :actual_move_in, :move_out_date, :start_date, :end_date, :unit_id]),
      select_merge: %{
        tenant_id: t.id,
        deposit_amount: coalesce(l.deposit_amount, 0) + coalesce(r.deposit_amount, 0),
        resident: fragment("? || ' ' || ?", t.first_name, t.last_name),
        charges: jsonize(c, [:id, :amount, :account, :expired])
      },
      group_by: [l.id, t.id, r.deposit_amount],
      order_by: [
        desc: l.start_date
      ],
      distinct: l.id
    )
  end

  #  Square	Market	Lease	Security
  #  Footage	Rent	Charges	Deposit
  #  Number of Units
  def total_real(real) do
    real
    |> Enum.reduce(
      %{sq_ft: 0, mr: 0, lc: 0, sd: 0, units: 0, balance: 0},
      fn r, acc ->
        %{
          sq_ft: acc.sq_ft + r.sq_footage,
          mr: acc.mr + r.market_rent,
          lc: acc.lc + total_lease_charges(r.charges),
          sd: acc.mr + r.deposit_amount,
          units: acc.units + 1,
          balance: acc.balance + r.balance
        }
      end
    )
  end

  defp total_lease_charges(charges) do
    charges
    |> Enum.reduce(0, fn c, acc -> acc + c["amount"] end)
  end

  # applicants, sq_foot and amount
  def total_potent(potent) do
    potent
    |> Enum.reduce(
      %{sq_ft: 0, applicants: 0, charges: 0},
      fn a, acc ->
        %{
          sq_ft: acc.sq_ft + a.sq_footage,
          applicants: acc.applicants + 1,
          charges: acc.charges + total_potent_charges(a)
        }
      end
    )
  end

  defp total_potent_charges(a) do
    Enum.reduce(a.payments, 0, &(&1["amount"] + &2))
  end

  def charges_summary(real, potent) do
    real =
      Enum.reduce(
        real,
        [],
        fn r, acc ->
          r.charges ++ acc
        end
      )

    Enum.reduce(
      potent,
      real,
      fn p, acc ->
        p.payments ++ acc
      end
    )
  end

  defp check_for_mtm(%{charges: charges} = unit_info) do
    cond do
      Enum.any?(charges, fn c -> c["account"] == "HAP Rent" end) ->
        unit_info

      Enum.any?(charges, fn c -> c["account"] == "Rent" && c["expired"] == true end) ->
        replace_rent_with_mr(charges, unit_info)

      true ->
        unit_info
    end
  end

  defp replace_rent_with_mr(charges, unit_info) do
    mtm_fee = get_mtm_fee(unit_info.unit_id)

    replaced =
      charges
      |> Enum.map(fn c ->
        cond do
          c["account"] == "Rent" && c["expired"] == true ->
            Map.merge(c, %{"amount" => unit_info.market_rent})

          true ->
            c
        end
      end)
      |> List.insert_at(0, %{"account" => "MTM Fees", "amount" => mtm_fee})

    Map.merge(unit_info, %{charges: replaced})
  end

  defp get_mtm_fee(unit_id) do
    from(
      u in Unit,
      join: p in assoc(u, :property),
      join: s in assoc(p, :setting),
      where: u.id == ^unit_id,
      select: s.mtm_fee,
      limit: 1
    )
    |> Repo.one()
  end

  def reduced_charges(charges) do
    sorted =
      charges
      |> Enum.filter(&(!is_nil(&1["amount"])))
      |> Enum.reduce(
        %{},
        fn c, acc ->
          case Map.has_key?(acc, c["account"]) do
            true -> Map.put(acc, c["account"], List.insert_at(acc[c["account"]], 0, c["amount"]))
            _ -> Map.put(acc, c["account"], [c["amount"]])
          end
        end
      )

    sorted
    |> Map.keys()
    |> Enum.map(&%{account: &1, total: sum(sorted[&1])})
    |> Enum.sort(&(&1.account <= &2.account))
  end

  defp sum(list), do: Enum.reduce(list, 0, &(&1 + &2))

  defp late_fee_account(), do: AppCount.Accounting.SpecialAccounts.get_account(:late_fees)
end
