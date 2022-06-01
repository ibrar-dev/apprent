defmodule AppCount.Admins.AccessServer do
  @moduledoc """
  """
  use GenServer
  alias AppCount.Admins.AccessServer
  alias AppCount.Core.ClientSchema

  require Logger

  defstruct admins: %{}, repo: AppCount.Admins.AccessServer.Loader

  # ---------  Client Interface  -------------

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %AccessServer{}, name: __MODULE__)
  end

  def property_ids_for(admin) do
    GenServer.call(__MODULE__, {:property_ids_for, admin})
  end

  def clear() do
    GenServer.call(__MODULE__, :clear)
  end

  def clear_admin(admin_id) do
    GenServer.call(__MODULE__, {:clear, admin_id})
  end

  def clear(admin_id) do
    GenServer.call(__MODULE__, {:clear, admin_id})
  end

  def filtered_property_ids_for(admin, candidate_property_ids) do
    candidate_map_set = candidate_property_ids |> MapSet.new()

    admin
    |> property_ids_for()
    |> MapSet.new()
    |> MapSet.intersection(candidate_map_set)
    |> MapSet.to_list()
  end

  def has_permission?(admin, property_id) do
    admin
    |> property_ids_for()
    |> Enum.member?(property_id)
  end

  # ---------  Server  -------------

  def init(_) do
    AppCount.GenserverLogger.starting(__MODULE__, "")
    schedule_next_load()
    {:ok, %AccessServer{}}
  end

  # ---------------------------------------------------------------- handle_call
  def handle_call(:clear, _from, %AccessServer{} = state) do
    state = new_state(state)
    {:reply, :ok, state}
  end

  def handle_call({:property_ids_for, admin}, _from, %AccessServer{} = state) do
    {state, property_ids} = lookup_or_load(state, admin)
    {:reply, property_ids, state}
  end

  def handle_call({:clear, admin_id}, _from, state) when is_integer(admin_id) do
    state = clear_admin_from_cache(state, admin_id)
    {:reply, :ok, state}
  end

  # ---------------------------------------------------------------- handle_info
  def handle_info(:clear, state) do
    state = new_state(state)
    {:noreply, state}
  end

  # ----------  Implementation ------

  def new_state(%AccessServer{repo: repo}) do
    %AccessServer{repo: repo}
  end

  def clear_admin_from_cache(%AccessServer{admins: admins} = state, admin_id) do
    admins = Map.drop(admins, [admin_id])
    %{state | admins: admins}
  end

  def add_to_cache(%AccessServer{admins: admins} = state, admin_id, property_ids) do
    admins = Map.put(admins, admin_id, property_ids)
    %{state | admins: admins}
  end

  def lookup_or_load(%AccessServer{admins: admins, repo: repo} = state, admin) do
    load_data_fn = fn ->
      repo.property_ids_for(ClientSchema.new("dasmen", admin))
    end

    property_ids = Map.get_lazy(admins, admin.id, load_data_fn)

    state =
      state
      |> add_to_cache(admin.id, property_ids)

    {state, property_ids}
  end

  defmodule Loader do
    import Ecto.Query
    alias AppCount.Repo

    def property_ids_for(admin, _) do
      property_ids_for(admin)
    end

    def property_ids_for(%AppCount.Core.ClientSchema{
          name: client_schema,
          attrs:
            %{
              id: _id,
              roles: %MapSet{
                map: %{
                  "Super Admin" => _
                }
              }
            } = _admin
        }) do
      from(
        p in AppCount.Properties.Property,
        join: s in assoc(p, :setting),
        select: p.id,
        where: s.active
      )
      |> Repo.all(prefix: client_schema)
    end

    def property_ids_for(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}) do
      from(
        region in AppCount.Admins.Region,
        join: perm in assoc(region, :permissions),
        join: scope in assoc(region, :scopings),
        join: property in assoc(scope, :property),
        join: setting in assoc(property, :setting),
        where: perm.admin_id == ^admin.id and setting.active,
        select: scope.property_id
      )
      |> Repo.all(prefix: client_schema)
    end
  end

  def schedule_next_load do
    minute_in_milliseconds = 60 * 1000
    five_minute_in_milliseconds = minute_in_milliseconds * 5
    hour_in_milliseconds = minute_in_milliseconds * 60

    drift = Enum.random(1..five_minute_in_milliseconds)
    interval = hour_in_milliseconds + drift
    Process.send_after(self(), :clear, interval)
  end
end
