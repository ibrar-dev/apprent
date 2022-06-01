defmodule AppCountAuth.AuthServer do
  use GenServer
  use AppCount.Data.PersistentState

  @valid_states [:refresh, :logout, :block]

  def block(user), do: set_status(user, :block)
  def force_new_login(user), do: set_status(user, :logout)
  def force_token_refresh(user), do: set_status(user, :refresh)
  def set_pass(user), do: GenServer.call(__MODULE__, {:unset, user})
  def reset(), do: GenServer.call(__MODULE__, :reset)

  def set_pass_on_new_login(user) do
    if get_status(user) == :logout do
      set_pass(user)
    end
  end

  def set_status(user, status) when status in @valid_states do
    GenServer.call(__MODULE__, {status, user})
  end

  def get_status(%{} = user) do
    GenServer.call(__MODULE__, user)
  end

  # ------- GenServer stuff -------

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, fetch_state() || %{}}
  end

  def handle_call({new_status, %{} = user}, _from, state)
      when new_status in @valid_states do
    new_state = Map.put(state, user_key(user), new_status)
    {:reply, :ok, persist_state(new_state)}
  end

  def handle_call({:unset, %{} = user}, _from, state) do
    new_state = Map.delete(state, user_key(user))
    {:reply, :ok, persist_state(new_state)}
  end

  def handle_call(%{} = user, _from, state) do
    key = user_key(user)
    {:reply, state[key] || :pass, state}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, persist_state(%{})}
  end

  defp user_key(user) do
    "#{user_type(user)}:#{user.client_schema}:#{user.id}"
  end

  defp user_type(user) do
    case user.__struct__ do
      AppCountAuth.Users.Admin ->
        "Admin"

      AppCountAuth.Users.Tenant ->
        "Tenant"

      AppCountAuth.Users.AppRent ->
        "AppRent"
        # TODO when techs are implemented
        #      AppCountAuth.Users.Tech -> "Tech"
    end
  end
end
