defmodule AppCount.Admins.Utils.Actions do
  alias AppCount.Repo
  alias AppCount.Admins.Action
  import Ecto.Query

  @spec list_actions(String.t()) :: list()
  def list_actions(%AppCount.Core.ClientSchema{name: client_schema, attrs: _}) do
    from(
      a in Action,
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :description, :params, :ip, :admin_id]),
      select_merge: %{
        admin: admin.name,
        ts: fragment("EXTRACT(EPOCH FROM ?)", a.inserted_at)
      },
      where: a.description != "Logged in",
      order_by: [
        desc: a.inserted_at
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_actions(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    from(
      a in Action,
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :description, :params, :ip, :admin_id]),
      select_merge: %{
        admin: admin.name,
        ts: fragment("EXTRACT(EPOCH FROM ?)", a.inserted_at)
      },
      where: admin.id == ^id and a.description != "Logged in",
      order_by: [
        desc: a.inserted_at
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def admin_delete(data, %AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
    record_admin_deletion(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, data)
    Repo.delete(data, prefix: client_schema)
  end

  def create_action(nil) do
    nil
  end

  def create_action(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      })
      when is_map(params) do
    %Action{}
    |> Action.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def create_action(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    %Action{}
    |> Action.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def record_admin_deletion(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, data) do
    id = "#{data.id}"
    fields = data.__struct__.__schema__(:fields)

    from(
      a in Action,
      where: a.admin_id == ^admin.id,
      where: a.type == "delete",
      where: fragment("? ->> 'id'", a.params) == ^id
    )
    |> Repo.one(prefix: client_schema)
    |> update_action(data, fields)
  end

  defp update_action(nil, _data, _fields) do
    {:error, "Action Not Found"}
  end

  defp update_action(
         action,
         data,
         fields
       ) do
    action
    |> Action.changeset(%{params: Map.take(data, fields)})
    |> Repo.update(prefix: action.__meta__.prefix)
  end

  def admins_actions_overview_three_months(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: admin_id
      }) do
    start_date =
      AppCount.current_time()
      |> Timex.shift(months: -2)
      |> Timex.beginning_of_month()

    from(
      a in Action,
      where: a.admin_id == ^admin_id and a.inserted_at >= ^start_date,
      select: %{
        id: a.id,
        description: a.description,
        date: fragment("date_trunc('month', ?) as date", a.inserted_at)
      },
      order_by: [
        asc: a.inserted_at
      ]
    )
    |> Repo.all(prefix: client_schema)
  end
end

require Protocol
Protocol.derive(Jason.Encoder, Plug.Upload)
