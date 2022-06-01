defmodule AppCount.Rewards.AccomplishmentRepo do
  alias AppCount.Repo
  alias AppCount.Rewards.Accomplishment
  alias AppCount.Rewards.Type
  alias AppCount.Rewards.Purchase
  alias AppCount.Tenants.TenancyRepo
  import Ecto.Query

  def list_accomplishments(tenant_id, nil) do
    accomplishments_query(tenant_id)
    |> Repo.all()
  end

  def list_accomplishments(tenant_id, start) do
    accomplishments_query(tenant_id)
    |> where([a], a.inserted_at > ^start)
    |> Repo.all()
  end

  def create_accomplishment(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{tenant_id: tenant_id, type: type_name}
      }) do
    with %{} = type <- Repo.get_by(Type, [name: type_name], prefix: client_schema),
         true <- type.active && can_reward?(tenant_id, :tenant),
         num when num > 0 <- num_left(tenant_id, type) do
      %Accomplishment{}
      |> Accomplishment.changeset(%{
        tenant_id: tenant_id,
        created_by: "Auto",
        reason: type.name,
        type_id: type.id,
        amount: type.points
      })
      |> Repo.insert(prefix: client_schema)
    else
      # TODO this reports errors incorrectly.  Needs tests
      nil -> {:error, "No such category."}
      false -> {:error, "Category is not active or rewards deactivated for this property."}
      _ -> {:error, "Tenant has reached max rewards for this month"}
    end
  end

  # This is all broke, tenant_id is now tenancy_id, but accomplishment requires a tenant_id.
  # Short fix so it works, will need to redo parts.
  def create_accomplishment(params) do
    # Move can_reward?/1 up the stack.  check before creating
    case can_reward?(params["tenant_id"]) do
      true ->
        tenancy = TenancyRepo.get(params["tenant_id"])

        params = %{params | "tenant_id" => tenancy.tenant_id}

        %Accomplishment{}
        |> Accomplishment.changeset(params)
        |> Repo.insert()

      _ ->
        IO.puts("Cannot receive rewards")
    end
  end

  def update_accomplishment(id, params) do
    Repo.get(Accomplishment, id)
    |> Accomplishment.changeset(params)
    |> Repo.update()
  end

  def delete_accomplishment(id) do
    Repo.get(Accomplishment, id)
    |> Repo.delete()
  end

  defp can_reward?(nil), do: false

  defp can_reward?(tenant_id) do
    # tenancy = TenancyRepo.active_tenancy_for_tenant(tenant_id)
    tenancy = TenancyRepo.get(tenant_id)

    if tenancy do
      TenancyRepo.tenancy_property_settings(tenancy.id)
      |> Map.get(:rewards)
    end
  end

  defp can_reward?(nil, :tenant), do: false

  defp can_reward?(tenant_id, :tenant) do
    tenancy = TenancyRepo.active_tenancy_for_tenant(tenant_id)

    if tenancy do
      TenancyRepo.tenancy_property_settings(tenancy.id)
      |> Map.get(:rewards)
    end
  end

  def num_left(tenant_id, type) do
    start =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    c =
      from(
        a in Accomplishment,
        where: a.tenant_id == ^tenant_id,
        where: a.type_id == ^type.id,
        where: a.inserted_at > ^start,
        select: count(a.id)
      )
      |> Repo.one()

    type.monthly_max - c
  end

  def accomplishments_given(tenant_id, type) do
    start =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    from(
      a in Accomplishment,
      where: a.tenant_id == ^tenant_id,
      where: a.type_id == ^type.id,
      where: a.inserted_at > ^start,
      select: count(a.id)
    )
    |> Repo.one()
  end

  def accomplishments_query(tenant_id) do
    from(
      a in Accomplishment,
      join: t in assoc(a, :type),
      select:
        map(a, [:id, :amount, :reason, :created_by, :reversal, :type_id, :inserted_at, :tenant_id]),
      select_merge: map(t, [:name, :icon]),
      where: a.tenant_id == ^tenant_id,
      order_by: [
        desc: a.inserted_at
      ]
    )
  end

  def tenant_points(tenant_id) do
    earned =
      from(
        a in Accomplishment,
        where: a.tenant_id == ^tenant_id,
        where: is_nil(a.reversal),
        select: sum(a.amount)
      )
      |> Repo.one()

    purchased =
      from(
        p in Purchase,
        where: p.tenant_id == ^tenant_id,
        select: sum(p.points)
      )
      |> Repo.one()

    (earned || 0) - (purchased || 0)
  end

  def tenant_history(tenant_id) do
    accomplishments =
      from(
        a in Accomplishment,
        join: t in assoc(a, :type),
        where: a.tenant_id == ^tenant_id,
        where: is_nil(a.reversal),
        select: map(a, [:id, :inserted_at, :amount]),
        select_merge: %{
          type: "accomplishment",
          name: t.name,
          icon: t.icon
        }
      )
      |> Repo.all()

    purchases =
      from(
        p in Purchase,
        join: pr in assoc(p, :reward),
        where: p.tenant_id == ^tenant_id,
        where: p.status != "canceled",
        select: map(p, [:id, :inserted_at, :status, :points]),
        select_merge: %{
          type: "purchase",
          name: pr.name,
          icon: pr.icon
        }
      )
      |> Repo.all()

    Enum.concat(purchases, accomplishments)
    |> Enum.sort(&(Timex.to_unix(&1.inserted_at) < Timex.to_unix(&2.inserted_at)))
    |> Enum.map_reduce(
      0,
      fn
        %{type: "purchase"} = t, total ->
          running = total - t.points
          {Map.put(t, :running, running), running}

        %{type: "accomplishment"} = t, total ->
          running = total + t.amount
          {Map.put(t, :running, running), running}
      end
    )
  end
end
