defmodule AppCount.Approvals.Utils.ApprovalsNotes do
  alias AppCount.Approvals.ApprovalNote
  alias AppCount.Repo
  alias AppCount.Approvals

  def create_approval_note(params) do
    %ApprovalNote{}
    |> ApprovalNote.changeset(params)
    |> Repo.insert()
    |> notify_mentions(params["mentions"])
  end

  def delete_approval_note(id) do
    Repo.get(ApprovalNote, id)
    |> Repo.delete()
  end

  defp notify_mentions({:ok, note}, nil), do: {:ok, note}

  defp notify_mentions({:ok, note}, admin_ids) do
    admin_ids
    |> Enum.each(fn admin_id -> Approvals.gentle_reminder(admin_id, note) end)

    {:ok, note}
  end

  defp notify_mentions({:error, e}, _), do: {:error, e}
end
