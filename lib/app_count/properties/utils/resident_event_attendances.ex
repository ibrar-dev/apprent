defmodule AppCount.Properties.Utils.ResidentEventAttendances do
  alias AppCount.Properties.ResidentEventAttendance
  alias AppCount.Repo
  require Logger

  def create_resident_event_attendance(params) do
    %ResidentEventAttendance{}
    |> ResidentEventAttendance.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, item} -> reward_resident(item)
      _ -> nil
    end
  end

  def delete_resident_event_attendance(id) do
    att = Repo.get(ResidentEventAttendance, id)

    att
    |> Repo.delete()
    |> case do
      {:ok, _} -> remove_reward(att.tenant_id)
      _ -> nil
    end
  end

  defp reward_resident(item) do
    {:ok, item}
  end

  defp remove_reward(tenant_id) do
    Logger.error("Removing from #{inspect(tenant_id)}")
  end
end
