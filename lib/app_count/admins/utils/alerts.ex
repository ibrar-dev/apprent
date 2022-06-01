defmodule AppCount.Admins.Utils.Alerts do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Admins.Alert
  alias AppCount.Admins.AlertRepo
  require Logger
  alias AppCount.Core.ClientSchema

  def get_total_unread(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    from(
      a in Alert,
      where: a.admin_id == ^admin_id and a.read == false,
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
  end

  def get_alerts(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    AlertRepo.list_alerts(%AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: admin_id
    })
  end

  def create_alert(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %Alert{}
    |> Alert.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> notify_admin_email
    |> notify_admin
    |> notify_admin_total
  end

  def create_alert(params, :nonsave) do
    notify_admin(params)
    |> notify_admin_total
  end

  def update_alert(id, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    Repo.get(Alert, id, prefix: client_schema)
    |> Alert.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_alert(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(Alert, id, prefix: client_schema)
    |> Repo.delete(prefix: client_schema)
  end

  def read_alert(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    history =
      from(
        a in Alert,
        where: a.id == ^id,
        select: a.history
      )
      |> Repo.one(prefix: client_schema)

    new_history =
      [%{change: "read", time: AppCount.current_time()}]
      |> Enum.concat(history || [])

    Repo.get(Alert, id, prefix: client_schema)
    |> Alert.changeset(%{read: true, history: new_history})
    |> Repo.update(prefix: client_schema)
  end

  def unread_alert(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    history =
      from(
        a in Alert,
        where: a.id == ^id,
        select: a.history
      )
      |> Repo.one(prefix: client_schema)

    new_history =
      [%{change: "unread", time: AppCount.current_time()}]
      |> Enum.concat(history || [])

    Repo.get(Alert, id, prefix: client_schema)
    |> Alert.changeset(%{read: false, history: new_history})
    |> Repo.update(prefix: client_schema)
  end

  defp notify_admin_email({:error, e}), do: Logger.error(inspect(e))

  defp notify_admin_email({:ok, alert}) do
    # TODO:SCHEMA fix get_aggregate
    alert = AlertRepo.get_aggregate(alert.id)

    AppCountCom.Admins.alert_created(alert.admin, alert)

    alert
  end

  def notify_admin(alert) do
    # FIX_DEPS
    # maybe decouple this with events, rather than just Module.concat()
    channel_module = Module.concat(["AppCountWeb.AlertsChannel"])
    channel_module.alert_notification(alert.admin_id, alert)
    alert
  end

  def notify_admin_total(alert) do
    # maybe decouple this with events, rather than just Module.concat()
    channel_module = Module.concat(["AppCountWeb.AlertsChannel"])

    # TODO:SCHEMA remove dsasmen
    channel_module.total_unread_alerts(
      alert.admin_id,
      get_total_unread(ClientSchema.new("dasmen", alert.admin_id))
    )

    alert
  end
end
