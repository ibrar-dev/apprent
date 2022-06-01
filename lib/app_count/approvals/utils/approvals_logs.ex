defmodule AppCount.Approvals.Utils.ApprovalsLogs do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Approvals
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Admins.Admin
  require Logger
  alias AppCount.Core.ClientSchema

  def create_log(%ClientSchema{attrs: %{"type" => type} = params, name: client_schema} = schema) do
    case type do
      "bug" -> gentle_reminder(schema)
      _ -> create_log(ClientSchema.new(client_schema, Map.delete(params, "type")))
    end
  end

  def create_log(%ClientSchema{attrs: params, name: client_schema}) do
    if can_update?(params) do
      %ApprovalLog{}
      |> ApprovalLog.changeset(params)
      |> Repo.insert(prefix: client_schema)
      |> notify(client_schema)
    else
      {:error,
       %{errors: [approval_id: {"already cancelled or declined", [validation: :required]}]}}
    end
  end

  def create_approval_log_bypass(params, client_schema) do
    %ApprovalLog{}
    |> ApprovalLog.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> notify(client_schema)
  end

  def delete_log(id, client_schema) do
    Repo.get(ApprovalLog, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  # Checks to see if there are any logs on there with a status of denied or cancelled. If yes then no more logs can be created.
  def can_update?(%{"approval_id" => approval_id} = _) do
    from(
      l in ApprovalLog,
      where: l.approval_id == ^approval_id and l.status in ["Declined", "Cancelled", "Denied"],
      select: count(l.id)
    )
    |> Repo.one()
    |> Kernel.==(0)

    #    |> check_status(status, admin_id, approval_id)
  end

  #  defp check_status(false, "Approved", admin_id, approval_id) do
  #    from(
  #      l in ApprovalLog,
  #      where: l.approval_id == ^approval_id and l.admin_id == ^admin_id and l.status in ["Declined", "Cancelled", "Denied"],
  #      select: count(l.id)
  #    )
  #    |> Repo.one
  #    |> Kernel.!=(0)
  #  end
  #  defp check_status(false, _, _, _), do: false
  #  defp check_status(true, _, _, _), do: true

  def notify({:error, _} = e, _), do: e

  def notify({:ok, log}, client_schema) do
    AppCount.Core.Tasker.start(fn ->
      handle_notifying(log, client_schema)
    end)

    {:ok, log}
  end

  def gentle_reminder(admin_id, note) do
    # TODO:SCHEMA remove show_approval
    approval = Approvals.show_approval(note.approval_id, "dasmen")
    admin = Repo.get(Admin, admin_id)
    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", approval.property_id))

    note =
      note
      |> Repo.preload(:admin)

    # approval, admin, note, property
    AppCount.Core.Tasker.start(fn ->
      AppCountCom.Approvals.gentle_reminder_note(approval, admin, note, property)
    end)

    {:ok, %{}}
  end

  def gentle_reminder(%ClientSchema{name: client_schema, attrs: params}) do
    approval = Approvals.show_approval(params["approval_id"], client_schema)
    admin = Repo.get(Admin, params["admin_id"])

    property =
      AppCount.Properties.get_property(ClientSchema.new(client_schema, approval.property_id))

    bugger = Repo.get(Admin, params["bugger_id"])

    AppCount.Core.Tasker.start(fn ->
      AppCountCom.Approvals.gentle_reminder(approval, admin, bugger, property)
    end)

    {:ok, %{}}
  end

  defp find_approval_logs(approval_id, admin_id) do
    ApprovalLog
    |> where([l], l.approval_id == ^approval_id and l.admin_id != ^admin_id)
    |> Repo.all()
  end

  defp handle_notifying(log, client_schema) do
    approval = Approvals.show_approval(log.approval_id, client_schema)
    admin = Repo.get(Admin, log.admin_id)

    token =
      token(%{admin_id: log.admin_id, approval_log_id: log.id, approval_id: log.approval_id})

    property = AppCount.Properties.get_property(ClientSchema.new("dasmen", approval.property_id))

    cond do
      log.status === "Approved" ->
        AppCount.Approvals.Utils.Approvals.find_emailer(
          approval,
          find_approval_logs(approval.id, admin.id),
          client_schema,
          admin
        )

        AppCountCom.Approvals.notify_approval_status(approval, admin, log, token, property)

      log.status === "Declined" || log.status === "More Info Requested" ->
        AppCountCom.Approvals.notify_approval_status(approval, admin, log, token, property)

      log.status === "Pending" ->
        AppCountCom.Approvals.notify_pending_of_approval(approval, admin, log, token, property)

      true ->
        Logger.warn("Not Hitting Expected Log Status, log.status: #{log.status}")
    end
  end

  def create_log_from_token(token, params, client_schema) do
    case verify(token) do
      {:ok, %{admin_id: admin_id, approval_log_id: log_id, approval_id: id}} ->
        verify_data(admin_id, log_id, id, params, client_schema)

      {:error, :invalid} ->
        {:error, "Invalid Entry"}

      {:error, :expired} ->
        {:error, "Expired Token"}
    end
  end

  def verify_data(admin_id, _, approval_id, params, client_schema) do
    if can_update?(%{"approval_id" => approval_id}) do
      from(
        l in ApprovalLog,
        where:
          l.admin_id == ^admin_id and l.approval_id == ^approval_id and l.status == "Pending",
        select: count(l.id)
      )
      |> Repo.one(prefix: client_schema)
      |> case do
        0 -> {:error, "Unauthorized Approval"}
        _ -> authorized_confirm_no_dupes(admin_id, approval_id, params, client_schema)
      end
    else
      {:error, "Already cancelled or declined"}
    end
  end

  def authorized_confirm_no_dupes(admin_id, approval_id, params, client_schema) do
    if params == "Approved" or params == "Declined" do
      from(
        l in ApprovalLog,
        where: l.admin_id == ^admin_id and l.approval_id == ^approval_id and l.status == ^params,
        select: count(l.id)
      )
      |> Repo.one(prefix: client_schema)
      |> case do
        0 ->
          create_log(
            ClientSchema.new(
              client_schema,
              %{"status" => params, "approval_id" => approval_id, "admin_id" => admin_id}
            )
          )

        _ ->
          {:error, "Already recorded #{params} at least once"}
      end
    else
      {:error, "Can only record Approved or Declined"}
    end
  end

  # FIX_DEPS  Better: move up stack
  def token(params) do
    AppCountWeb.Token.token(params)
  end

  def verify(token) do
    AppCountWeb.Token.verify(token)
  end
end
