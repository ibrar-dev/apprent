defmodule AppCount.Approvals.Utils.ApprovalsAdminData do
  import AppCount.EctoExtensions
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Approvals
  alias AppCount.Approvals.Approval
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Approvals.ApprovalNote
  alias AppCount.Approvals.ApprovalCost

  def list_admin_data(admin_id, property_id) when is_binary(admin_id) do
    {id, _} = Integer.parse(admin_id)
    list_admin_data(id, property_id)
  end

  def list_admin_data(admin_id, property_id) do
    pending = Approvals.list_approvals(admin_id, :pending, [property_id])
    logs = fetch_approval_logs(admin_id, property_id)
    mentions = fetch_mentions(admin_id)
    approvals = fetch_approvals(admin_id, property_id)
    #    costs = fetch_costs(admin_id)
    %{
      pending: pending,
      logs: logs,
      mentions: mentions,
      approvals: approvals
    }
  end

  def fetch_approval_logs(admin_id, property_id) do
    property_filter =
      if property_id != "-1" do
        dynamic([_, a], a.property_id == ^property_id)
      else
        true
      end

    from(
      l in ApprovalLog,
      join: a in assoc(l, :approval),
      join: p in assoc(a, :property),
      where: l.admin_id == ^admin_id,
      select: map(l, [:id, :status, :approval_id, :inserted_at]),
      select_merge: %{
        params: a.params,
        num: a.num
      },
      order_by: [desc: :inserted_at]
    )
    |> where(^property_filter)
    |> Repo.all()
  end

  def fetch_mentions(admin_id) do
    name = Repo.get(Admins.Admin, admin_id).name

    from(
      n in ApprovalNote,
      join: a in assoc(n, :admin),
      where: ilike(n.note, ^"%#{name}%"),
      select: map(n, [:id, :admin_id, :note, :inserted_at, :approval_id]),
      select_merge: %{
        admin: a.name,
        email: a.email
      }
    )
    |> Repo.all()
  end

  def fetch_approvals(admin_id, property_id) do
    property_filter =
      if property_id != "-1" do
        dynamic([a], a.property_id == ^property_id)
      else
        true
      end

    log_query =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          approval_id: l.approval_id,
          approvals:
            jsonize(
              l,
              [
                :id,
                :admin_id,
                :inserted_at,
                :status,
                :notes,
                {:admin, a.name},
                {:email, a.email}
              ],
              l.inserted_at,
              "DESC"
            )
        },
        group_by: [l.approval_id]
      )

    notes_query =
      from(
        n in ApprovalNote,
        join: a in assoc(n, :admin),
        select: %{
          id: n.id,
          note: n.note,
          admin_id: n.admin_id,
          admin: a.name,
          email: a.email,
          inserted_at: n.inserted_at,
          approval_id: n.approval_id
        },
        order_by: [
          desc: :inserted_at
        ]
      )

    from(
      a in Approval,
      left_join: l in subquery(log_query),
      on: l.approval_id == a.id,
      left_join: n in subquery(notes_query),
      on: n.approval_id == a.id,
      left_join: at in assoc(a, :attachments),
      left_join: up in assoc(at, :attachment),
      left_join: url in assoc(at, :attachment_url),
      left_join: property in assoc(a, :property),
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :type, :notes, :params, :property_id, :inserted_at, :num]),
      select_merge: %{
        requestor: map(admin, [:id, :name, :email]),
        logs: l.approvals,
        attachments:
          type(
            jsonize(at, [:id, {:url, url.url}, {:content_type, up.content_type}]),
            AppCount.Data.Uploads
          ),
        admin_notes: jsonize(n, [:id, :note, :admin_id, :admin, :email, :inserted_at]),
        property: property.name
      },
      where: a.admin_id == ^admin_id,
      order_by: [
        asc: :inserted_at
      ],
      group_by: [a.id, admin.id, l.approvals, property.id]
    )
    |> where(^property_filter)
    |> Repo.all()
  end

  def fetch_costs(property_id) do
    start_date =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    from(
      cat in AppCount.Accounting.Category,
      join: c in subquery(amount_spent_query(start_date)),
      on: fragment("? = ? AND ? = ?", cat.id, c.category_id, c.property_id, ^property_id),
      select: %{
        id: cat.id,
        name: cat.name,
        amount: c.amount
      }
    )
    |> Repo.all()
  end

  def amount_spent_query(start_date) do
    end_date =
      AppCount.current_time()
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
        where: is_nil(t.id),
        select: %{
          id: a.id,
          admin_id: a.admin_id,
          inserted_at: a.inserted_at,
          property_id: a.property_id
        }
      )

    from(
      c in ApprovalCost,
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        amount: sum(c.amount),
        property_id: a.property_id,
        category_id: c.category_id
      },
      group_by: [a.property_id, c.category_id]
    )
  end
end
