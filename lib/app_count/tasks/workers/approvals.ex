defmodule AppCount.Tasks.Workers.Approvals do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Admins.Admin
  use AppCount.Tasks.Worker, "Notify pending approvals"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    admins = list_admins_with_pending(schema)

    case length(admins) do
      0 -> nil
      _ -> Enum.each(admins, &send_daily_email(&1))
    end
  end

  def send_daily_email(admin_id) do
    property_ids =
      %Admin{id: admin_id}
      |> AppCount.Admins.property_ids_for()

    AppCount.Core.Tasker.start(fn ->
      pending =
        AppCount.Approvals.Utils.Approvals.list_approvals(admin_id, :pending, property_ids)

      admin = Repo.get(Admin, admin_id)
      AppCountCom.Approvals.daily_pending_approvals(admin, pending)
    end)

    :ok
  end

  def list_admins_with_pending(schema) do
    declined =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    sub =
      from(
        l in ApprovalLog,
        select: %{
          admin_id: l.admin_id,
          approval_id: l.approval_id,
          status: l.status,
          current_status:
            fragment(
              "FIRST_VALUE(?) OVER( PARTITION BY ?, ? ORDER BY ? DESC RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)",
              l.status,
              l.approval_id,
              l.admin_id,
              l.inserted_at
            )
        }
      )

    from(
      l in subquery(sub),
      left_join: dc in subquery(declined),
      on: dc.approval_id == l.approval_id,
      select: l.admin_id,
      distinct: l.admin_id,
      where: l.current_status == "Pending" and is_nil(dc.status)
    )
    |> Repo.all(prefix: schema)
  end
end
