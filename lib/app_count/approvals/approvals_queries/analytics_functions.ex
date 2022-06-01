defmodule AppCount.Approvals.Utils.ApprovalsQueries.AnalyticsFunctions do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Approvals.Approval
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Approvals.ApprovalCost
  alias AppCount.Core.ClientSchema

  # returns an object with an mtd k/v and ytd k/v
  # returns the total amount of approvals that do not have ALL the approvals.
  def pending_approval(property_ids) do
    mtd = pending_approval_query(property_ids, mtd())
    ytd = pending_approval_query(property_ids, ytd())

    %{
      mtd: mtd,
      ytd: ytd
    }
  end

  # returns an object with an mtd k/v and ytd k/v
  def approved(property_ids) do
    mtd = approved_query(property_ids, mtd())
    ytd = approved_query(property_ids, ytd())

    %{
      mtd: mtd,
      ytd: ytd
    }
  end

  # returns an object with an mtd k/v and ytd k/v
  def denied(property_ids) do
    mtd = denied_query(property_ids, mtd())
    ytd = denied_query(property_ids, ytd())

    %{
      mtd: mtd,
      ytd: ytd
    }
  end

  # returns an object with an mtd k/v and ytd k/v
  # returns the first category
  def most_expensed_category(%ClientSchema{attrs: property_ids, name: client_schema}) do
    mtd =
      categories_with_expenses(property_ids, mtd())
      |> Repo.all(prefix: client_schema)
      |> Enum.sort_by(&Decimal.to_float(&1.amount), :desc)
      |> List.first()

    ytd =
      categories_with_expenses(property_ids, ytd())
      |> Repo.all(prefix: client_schema)
      |> Enum.sort_by(&Decimal.to_float(&1.amount), :desc)
      |> List.first()

    %{
      mtd: mtd,
      ytd: ytd
    }
  end

  # returns an object with an mtd k/v and ytd k/v
  # returns the vendor with the most expenses
  def most_expensed_payee(property_ids) do
    # expensedPayeeQuery(property_ids, ytd())
    mtd = expensedPayeeQuery(property_ids, mtd())
    ytd = expensedPayeeQuery(property_ids, ytd())

    %{
      mtd: mtd,
      ytd: ytd
    }
  end

  # Get the amount approved and then the amount of units and divide
  def approved_per_unit(%ClientSchema{} = property_ids) do
    units = get_units_count(property_ids)

    mtd_amount =
      approved_query(property_ids, mtd())
      |> Decimal.div(units)

    ytd_amount =
      approved_query(property_ids, ytd())
      |> Decimal.div(units)

    %{
      mtd: mtd_amount,
      ytd: ytd_amount
    }
  end

  # the thought is this query supplies ALL the costs for the properties and the dates
  # the function that then calls this query is free to do what it wants with the info
  # it will return an array ocosts each cost will have an array of logs and whether it was invoiced or not
  # it would be nice if the array of logs only had one per admin and the most recent one.
  def costs_query(property_ids, dates) do
    [start_date, end_date] = get_dates(dates)

    from(
      a in Approval,
      left_join: c in assoc(a, :approval_costs),
      left_join: cat in assoc(c, :category),
      join: l in assoc(a, :approval_logs),
      where:
        a.property_id in ^property_ids and a.inserted_at <= ^end_date and
          a.inserted_at >= ^start_date,
      preload: [approval_logs: l, approval_costs: {c, category: cat}]
    )
  end

  # get all the costs for the given date:
  # filter out only ones that have a pending, that have no decline and an invoiced of nil
  # sum the total? or let the front end do that
  def pending_approval_query(%ClientSchema{attrs: property_ids, name: client_schema}, dates) do
    costs_query(property_ids, dates)
    |> Repo.all(prefix: client_schema)
    |> Enum.filter(&is_pending(&1))
    |> Enum.reduce(Decimal.new(0), fn a, acc ->
      total =
        Enum.reduce(a.approval_costs, Decimal.new(0), fn c, new_acc ->
          Decimal.add(c.amount, new_acc)
        end)

      Decimal.add(total, acc)
    end)
  end

  def approved_query(%ClientSchema{attrs: property_ids, name: client_schema}, dates) do
    costs_query(property_ids, dates)
    |> Repo.all(prefix: client_schema)
    |> Enum.filter(&is_approved(&1))
    |> Enum.reduce(Decimal.new(0), fn a, acc ->
      total =
        Enum.reduce(a.approval_costs, Decimal.new(0), fn c, new_acc ->
          Decimal.add(c.amount, new_acc)
        end)

      Decimal.add(total, acc)
    end)
  end

  def approved_query_old(property_ids, dates) do
    [start_date, end_date] = get_dates(dates)

    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    approval =
      from(
        a in Approval,
        left_join: t in subquery(rejected),
        on: t.approval_id == a.id,
        where: is_nil(t.id) and a.property_id in ^property_ids,
        select: %{
          id: a.id,
          inserted_at: a.inserted_at,
          payee_id: fragment("(params->>'payee_id')::integer")
        }
      )

    from(
      c in ApprovalCost,
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        amount: sum(c.amount)
      }
    )
  end

  def approved_query_with_extra(property_ids, dates) do
    approved_query_old(property_ids, dates)
    |> select_merge([c], %{id: c.category_id})
    |> group_by([c], [c.category_id])
  end

  def denied_query(%ClientSchema{attrs: property_ids, name: client_schema}, dates) do
    costs_query(property_ids, dates)
    |> Repo.all(prefix: client_schema)
    |> Enum.filter(&is_denied(&1))
    |> Enum.reduce(Decimal.new(0), fn a, acc ->
      total =
        Enum.reduce(a.approval_costs, Decimal.new(0), fn c, new_acc ->
          Decimal.add(c.amount, new_acc)
        end)

      Decimal.add(total, acc)
    end)
  end

  def categories_with_expenses(property_ids, dates) do
    from(
      c in AppCount.Accounting.Category,
      left_join: s in subquery(approved_query_with_extra(property_ids, dates)),
      on: c.id == s.id,
      where: c.is_balance == false and c.in_approvals,
      select: %{
        id: c.id,
        name: c.name,
        number: c.num,
        amount: fragment("CASE WHEN ? IS NULL THEN 0 ELSE ? END", s.amount, s.amount)
      },
      order_by: [asc: :name]
    )
  end

  # fragment("(params->>'payee_id')::integer") == ^payee_id
  def expensedPayeeQuery(%ClientSchema{attrs: property_ids, name: client_schema}, dates) do
    payee_subquery =
      from(
        p in AppCount.Accounting.Payee,
        select: %{
          id: p.id,
          name: p.name
        }
      )

    approved_query_old(property_ids, dates)
    |> join(:inner, [_, a], p in subquery(payee_subquery), on: a.payee_id == p.id)
    |> select_merge([_, _, p], %{payee_id: p.id, name: p.name})
    |> group_by([_, _, p], [p.id, p.name])
    |> Repo.all(prefix: client_schema)
    |> Enum.sort_by(&Decimal.to_float(&1.amount), :desc)
    |> List.first()
  end

  defp get_units_count(%ClientSchema{attrs: property_ids, name: client_schema}) do
    from(
      p in AppCount.Properties.Property,
      where: p.id in ^property_ids,
      join: u in assoc(p, :units),
      select: count(u.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def is_pending(%{approval_logs: logs, params: params}) do
    cond do
      not is_nil(params["invoice_date"]) -> false
      true -> check_logs(logs, :pending)
    end
  end

  def is_approved(%{approval_logs: logs}) do
    check_logs(logs, :approved)
  end

  def is_denied(%{approval_logs: logs}) do
    Enum.filter(logs, &(!&1.deleted))
    |> Enum.any?(&(&1.status in ["Declined", "Cancelled", "Denied"]))
  end

  defp check_logs(logs, :pending) do
    # this will make them uniq by admin_id and hopefully only show most recent
    sorted =
      Enum.sort_by(logs, & &1.id, :desc)
      |> Enum.uniq_by(& &1.admin_id)
      |> Enum.filter(&(!&1.deleted))

    case Enum.any?(logs, &(&1.status in ["Declined", "Cancelled", "Denied"])) do
      true -> false
      _ -> !Enum.all?(sorted, &(&1.status == "Approved"))
    end
  end

  defp check_logs(logs, :approved) do
    # this will make them uniq by admin_id and hopefully only show most recent
    sorted =
      Enum.sort_by(logs, & &1.id, :desc)
      |> Enum.uniq_by(& &1.admin_id)
      |> Enum.filter(&(!&1.deleted))

    case Enum.any?(logs, &(&1.status in ["Declined", "Cancelled", "Denied"])) do
      true -> false
      _ -> Enum.all?(sorted, &(&1.status == "Approved"))
    end
  end

  def get_dates(dates) when is_binary(dates) do
    start_d =
      String.split(dates, ",")
      |> List.first()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.beginning_of_day()

    end_d =
      String.split(dates, ",")
      |> List.last()
      |> Timex.parse!("{YYYY}-{0M}-{0D}")
      |> Timex.end_of_day()

    [start_d, end_d]
  end

  def get_dates(dates) when is_list(dates) do
    [List.first(dates), List.last(dates)]
  end

  def mtd(),
    do: [
      Timex.beginning_of_month(AppCount.current_time()),
      Timex.end_of_day(AppCount.current_time())
    ]

  def ytd(),
    do: [
      Timex.beginning_of_year(AppCount.current_time()),
      Timex.end_of_day(AppCount.current_time())
    ]
end
