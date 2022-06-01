defmodule AppCount.Reports.Queries.EffectiveRent do
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.Decimal
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.Charge
  alias AppCount.Properties.Unit

  def effective_rent(property_id, date) when is_binary(date) do
    effective_rent(property_id, Date.from_iso8601!(date))
  end

  # enter a property_id and as of date and it should spit out a query that returns the unit_id, lease_id, effective rent of the date and total lease value, lease start and lease_end/move_out
  def effective_rent(property_id, date) do
    rent_ids = [
      AppCount.Accounting.SpecialAccounts.get_account(:rent).id,
      AppCount.Accounting.SpecialAccounts.get_account(:hap_rent).id
    ]

    %{start_d: start_d, end_d: end_d} = convert_month_to_dates(date)
    # TO GET ALL THE LEASE CHARGES ON A LEASE TO CALCULATE FUTURE AMOUNTS
    charges_query =
      from(
        c in AppCount.Properties.Charge,
        where: is_nil(c.to_date) or c.to_date >= ^date,
        where: c.account_id in ^rent_ids or c.amount < 0,
        select: %{
          id: c.id,
          lease_id: c.lease_id,
          amount: c.amount,
          account_id: c.account_id,
          to_date: c.to_date
        }
      )

    # TO GET ALL THE CHARGES ALREADY ON A LEASE PRIOR TO THE AS OF DATE
    bills_query =
      from(
        c in Charge,
        where: c.bill_date <= ^date and c.account_id in ^rent_ids and is_nil(c.reversal_id),
        select: %{
          id: c.id,
          amount: c.amount,
          lease_id: c.lease_id,
          bill_date: c.bill_date
        }
      )

    # TO GET ALL THE RENT/HAPRENT CHARGES DURING THE MONTH AS OF (to calculate the potential rent)
    charged_month_as_of =
      from(
        c in Charge,
        where:
          c.bill_date >= ^start_d and c.bill_date <= ^end_d and c.account_id in ^rent_ids and
            is_nil(c.reversal_id),
        select: %{
          id: c.id,
          lease_id: c.lease_id,
          amount: c.amount,
          bill_date: c.bill_date
        },
        distinct: [c.id]
      )

    # TO GET ALL THE CONCESSIONS DURING THE MONTH AS OF (to deduct from potential to get to effective rent)
    concessions_month_as_of =
      from(
        c in Charge,
        where:
          c.bill_date >= ^start_d and c.bill_date <= ^end_d and c.amount < 0 and
            is_nil(c.reversal_id),
        select: %{
          id: c.id,
          lease_id: c.lease_id,
          amount: c.amount,
          bill_date: c.bill_date
        },
        distinct: [c.id]
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: t in assoc(l, :tenants),
      left_join: cm in subquery(charged_month_as_of),
      on: l.id == cm.lease_id,
      left_join: concm in subquery(concessions_month_as_of),
      on: concm.lease_id == l.id,
      left_join: prevb in subquery(bills_query),
      on: prevb.lease_id == l.id,
      left_join: futb in subquery(charges_query),
      on: futb.lease_id == l.id,
      where: u.property_id == ^property_id,
      where:
        l.start_date <= ^date and l.end_date >= ^date and not is_nil(l.actual_move_in) and
          l.actual_move_in <= ^date,
      select: %{
        id: l.id,
        unit_id: l.unit_id,
        months_charges: jsonize(cm, [:id, :amount, :bill_date]),
        months_concessions: jsonize(concm, [:id, :amount, :bill_date]),
        previous_charges: jsonize(prevb, [:id, :amount, :bill_date]),
        future_charges: jsonize(futb, [:id, :amount, :account_id, :to_date]),
        tenants:
          jsonize(t, [:id, {:full_name, fragment("? || ' ' || ?", t.first_name, t.last_name)}]),
        start_date: l.start_date,
        end_date:
          fragment(
            "CASE WHEN ? IS NULL THEN ? ELSE ? END",
            l.move_out_date,
            l.end_date,
            l.move_out_date
          ),
        actual_move_in: l.actual_move_in
      },
      group_by: [l.id]
    )
  end

  def effective_rent_unit(unit_id, date) do
    unit = Repo.get(Unit, unit_id)

    effective_rent(unit.property_id, date)
    |> where([l], l.unit_id == ^unit_id)
  end

  defp convert_month_to_dates(month) do
    cond do
      is_nil(month) ->
        %{
          start_d: Timex.beginning_of_month(AppCount.current_date()),
          end_d: Timex.end_of_month(AppCount.current_date())
        }

      Timex.is_valid?(month) ->
        %{start_d: Timex.beginning_of_month(month), end_d: Timex.end_of_month(month)}

      true ->
        Date.from_iso8601!(month) |> convert_month_to_dates
    end
  end

  def compute_rent(_lease_id) do
    rent_ids = [
      AppCount.Accounting.SpecialAccounts.get_account(:rent).id,
      AppCount.Accounting.SpecialAccounts.get_account(:hap_rent).id
    ]

    from(
      c in AppCount.Properties.Charge,
      join: l in assoc(c, :lease),
      where: c.account_id in ^rent_ids or c.amount < 0,
      select: %{
        id: c.id,
        amount: c.amount,
        start_date:
          fragment("CASE WHEN ? IS NIL ? ELSE ? END", c.from_date, l.start_date, c.from_date),
        end_date: fragment("CASE WHEN ? IS NIL ? ELSE ? END", c.to_date, l.end_date, c.to_date)
      }
    )
    |> Repo.all()

    #    |> Enum.map(& compute_charge(&1))
  end

  def compute_charge(%{amount: _amount, start_date: _start_d, end_date: _end_d} = _charge) do
    #    compute_charge(amount, start_date, end_date, get_month_status(start_d, "start"), prorated_rent(amount, start_d.day, Timex.days_in_month(start_d)))
  end

  #  def compute_charge(amount, start_date, end_date, {:prorate, "start"}, prorated_rent(amount, , Timex.days_in_month(start_date)))

  #  def compute_rent(rent, start_date, end_date, true, total), do: compute_rent(rent, shift_month(start_date), end_date, false, prorated_rent(rent, start_date))
  #  def compute_rent(rent, start_date, end_date, false, total), do: compute_rent(rent, shift_month(start_date), end_date, false, rent + total)
  #  def shift_month(date), do: Timex.shift(date, months: 1) |> Timex.beginning_of_month

  #  def prorated_rent(rent, date) do
  #    case get_month_status(date) do
  #      {:full, _} -> rent
  #      {:prorate, num_days} -> prorated_rent(rent, num_days, Timex.days_in_month(date))
  #    end
  #  end

  def prorated_rent(rent, num_days, days_in_month), do: rent / days_in_month * num_days

  # false means dont prorate, true means prorate
  def get_month_status(date, "start") do
    cond do
      date.day == 1 -> {:full, "start"}
      true -> {:prorate, "start"}
    end
  end

  def get_month_status(date, "end") do
    cond do
      date.day == Timex.days_in_month(date) -> {:full, "end"}
      true -> {:prorate, "end"}
    end
  end

  def get_month_status(_date, _), do: {:full, ""}

  #  def get_month_status(date, :type) do

  #    cond do
  #      Timex.compare(date, Timex.end_of_month(date)) == 0 -> {:full, date.day}
  #      true -> {:prorate, date.day}
  #    end
  #  end
end
