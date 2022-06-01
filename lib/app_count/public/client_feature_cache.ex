defmodule AppCount.Public.ClientFeaturesCache do
  use GenServer
  alias AppCount.Repo
  alias AppCount.Public.ClientModule
  import Ecto.Query, only: [from: 2]

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      [
        {:ets_table_name, :link_cache_table},
        {:log_limit, 1_000_000}
      ],
      opts
    )
  end

  def get(slug) do
    case :ets.lookup(:link_cache_table, slug) do
      [] -> {:not_found}
      [{_slug, result}] -> result
    end
  end

  def get_client_module(client, feature) do
    case GenServer.call(__MODULE__, {:get, client}) do
      [] -> {:not_found}
      [{_slug, result}] -> Map.fetch!(result, feature)
    end
  end

  def set(slug) do
    case :ets.insert(:link_cache_table, {slug}) do
      true -> {:reply, slug}
    end
  end

  def add(client) do
    client
    |> Enum.reduce(%{}, fn obj, final ->
      x = Map.get(final, "client_#{obj.client_id}", %{})
      x = Map.put(x, obj.flag_name, obj.enabled)
      Map.put(final, "client_#{obj.client_id}", x)
    end)
    |> Enum.each(fn client ->
      true = :ets.insert_new(:link_cache_table, client)
    end)

    %ClientModule{}
    |> ClientModule.changeset(client)
    |> Repo.insert()
  end

  def update(slug, feature, value) do
    case get(slug) do
      {:not_found} ->
        {:not_found}

      {:found, result} ->
        Enum.reduce(result, %{}, fn obj, final ->
          x = Map.get(final, "client_#{obj.client_id}", %{})
          x = Map.put(x, feature, value)
          Map.put(final, "client_#{obj.client_id}", x)
        end)
        |> Enum.each(fn client ->
          true = :ets.insert(:link_cache_table, client)

          Repo.get(ClientModule, slug)
          |> ClientModule.changeset(%{flag_name: feature, enabled: value})
          |> Repo.update()
        end)
    end
  end

  def init(args) do
    # Setup ets table
    [{:ets_table_name, ets_table_name}, {:log_limit, log_limit}] = args
    :ets.new(ets_table_name, [:named_table, :set, :public])
    # get clien infromation from the table and store it in ets table
    from(
      cf in ClientModule,
      select: %{
        client_id: cf.client_id,
        module_id: cf.module_id,
        enabled: cf.enabled
      }
    )
    |> Repo.all()
    |> Enum.reduce(%{}, fn obj, final ->
      x = Map.get(final, "client_#{obj.client_id}", %{})
      x = Map.put(x, obj.flag_name, obj.enabled)
      Map.put(final, "client_#{obj.client_id}", x)
    end)
    |> Enum.each(fn client ->
      true = :ets.insert_new(ets_table_name, client)
    end)

    # result = :ets.lookup(ets_table_name, "client_1")
    {:ok, %{log_limit: log_limit, ets_table_name: ets_table_name}}
  end
end
