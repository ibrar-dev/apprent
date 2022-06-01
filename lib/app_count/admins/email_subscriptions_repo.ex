defmodule AppCount.Admins.EmailSubscriptionsRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Admins.EmailSubscription,
    preloads: [:admin]

  def get_subscriptions(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin_id}) do
    from(
      sub in @schema,
      where: sub.admin_id == ^admin_id
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.map(&%{id: &1.id, active: &1.active, trigger: &1.trigger})
  end

  def get_admins(%AppCount.Core.ClientSchema{name: client_schema, attrs: trigger}) do
    from(
      sub in @schema,
      where: sub.trigger == ^trigger,
      where: sub.active,
      preload: ^@preloads
    )
    |> Repo.all(prefix: client_schema)
  end

  def subscribed?(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin_id}, trigger) do
    from(
      sub in @schema,
      where: sub.admin_id == ^admin_id,
      where: sub.trigger == ^trigger,
      where: sub.active
    )
    |> Repo.all(prefix: client_schema)
    |> length != 0
  end

  def subscribe(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin_id}, trigger) do
    case Repo.get_by(@schema, [admin_id: admin_id, trigger: trigger], prefix: client_schema) do
      nil ->
        %{
          admin_id: admin_id,
          trigger: trigger,
          active: true
        }
        |> insert(prefix: client_schema)

      sub ->
        @schema.changeset(sub, %{active: true})
        |> Repo.update(prefix: client_schema)
    end
  end

  def unsubscribe(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin_id}, trigger) do
    Repo.get_by(@schema, [admin_id: admin_id, trigger: trigger], prefix: client_schema)
    |> @schema.changeset(%{active: false})
    |> Repo.update(prefix: client_schema)

    # The below doesnt work for some reason.
    # get_by(@schema, admin_id: admin_id, trigger: trigger)
    # |> update(%{active: false})
  end
end
