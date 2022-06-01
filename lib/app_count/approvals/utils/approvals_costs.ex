defmodule AppCount.Approvals.Utils.ApprovalCosts do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Approvals.Approval
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Approvals.ApprovalCost

  def update(id, params) do
    Repo.get(ApprovalCost, id)
    |> ApprovalCost.changeset(params)
    |> Repo.update()
  end

  def delete_all(approval_id) do
    from(
      c in ApprovalCost,
      where: c.approval_id == ^approval_id,
      select: c
    )
    |> Repo.all()
    |> Enum.each(&Repo.delete(&1))
  end

  def get_spent(category_id, property_id) do
    approvals =
      from(
        a in Approval,
        join: c in assoc(a, :approval_costs),
        join: n in assoc(c, :category),
        join: admin in assoc(a, :admin),
        left_join: l in assoc(a, :approval_logs),
        left_join: la in assoc(l, :admin),
        select: %{
          id: a.id,
          params: a.params,
          type: a.type,
          inserted_at: a.inserted_at,
          request_type: a.type,
          num: a.num,
          admin: admin.name,
          costs: jsonize(c, [:id, :amount, {:category, n.name}, :category_id]),
          logs:
            jsonize(l, [:id, :status, :notes, :inserted_at, :admin_id, :notes, {:admin, la.name}])
        },
        group_by: [a.id, admin.name]
      )

    from(
      c in AppCount.Accounting.Category,
      join: s in subquery(spent_query(property_id, AppCount.current_time())),
      on: s.id == c.id,
      join: a in subquery(approvals),
      on: a.id in s.approvals,
      where: c.id == ^category_id,
      select: %{
        id: c.id,
        total: s.amount,
        name: c.name,
        approvals:
          jsonize(a, [:id, :params, :request_type, :inserted_at, :num, :admin, :costs, :logs])
      },
      group_by: [c.id, s.amount]
    )
    |> Repo.one()
  end

  def spent_query(property_id, date) when is_nil(date),
    do: spent_query(property_id, AppCount.current_date())

  def spent_query(property_id, date) when is_binary(date),
    do: spent_query(property_id, Timex.parse!(date, "{YYYY}-{0M}-{D}"))

  def spent_query(property_id, date) do
    start_date =
      date
      |> Timex.beginning_of_month()

    end_date =
      date
      |> Timex.end_of_month()

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
        where: is_nil(t.id) and a.property_id == ^property_id,
        select: %{
          id: a.id,
          inserted_at: a.inserted_at
        }
      )

    from(
      c in ApprovalCost,
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        id: c.category_id,
        approvals: fragment("ARRAY_AGG(?)", a.id),
        amount: sum(c.amount)
      },
      group_by: [c.category_id]
    )
  end

  def list_categories_for_approval(property_id) do
    from(
      c in AppCount.Accounting.Category,
      left_join: s in subquery(spent_query(property_id, AppCount.current_time())),
      on: c.id == s.id,
      where: c.is_balance == false and c.in_approvals,
      select: %{
        id: c.id,
        name: c.name,
        num: c.num,
        spent: fragment("CASE WHEN ? IS NULL THEN 0 ELSE ? END", s.amount, s.amount),
        approvals: s.approvals
      },
      order_by: [asc: :name]
    )
    |> Repo.all()
  end
end
