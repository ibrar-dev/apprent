defmodule AppCount.Admins.AlertRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Admins.Alert,
    preloads: [admin: [], attachment_url: []]

  def list_alerts(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    list_alerts_query(admin_id)
    |> preload(^@preloads)
    |> Repo.all(prefix: client_schema)
  end

  # Will get all alerts after a specific date.
  def list_alerts(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin_id
        },
        date
      ) do
    list_alerts_query(admin_id)
    |> where([a], a.inserted_at >= ^date)
    |> Repo.all(prefix: client_schema)
  end

  defp list_alerts_query(admin_id) do
    from(
      a in @schema,
      where: a.admin_id == ^admin_id,
      order_by: [desc: :inserted_at]
    )
  end
end
