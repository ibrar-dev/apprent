defmodule AppCount.Tasks.Queue do
  use GenServer
  use AppCount.Data.PersistentState
  @max_tasks 10
  @process_name :task_queue

  def enqueue(description, func, arguments, client_schema)
      when is_binary(description) and is_function(func) and is_list(arguments) and
             is_binary(client_schema) do
    GenServer.call(@process_name, {description, func, arguments, client_schema})
  end

  def num_slots, do: GenServer.call(@process_name, :num_slots)
  def queue, do: GenServer.call(@process_name, :queue)
  def pop, do: GenServer.call(@process_name, :pop)

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    GenServer.start_link(__MODULE__, [], name: @process_name)
  end

  def init(_) do
    {:ok, %{queue: fetch_state() || [], num_slots: @max_tasks}}
  end

  def handle_call(:queue, _, %{queue: q} = state), do: {:reply, q, state}
  def handle_call(:num_slots, _, %{num_slots: num} = state), do: {:reply, num, state}

  def handle_call({description, func, arguments, client_schema}, _, %{num_slots: num, queue: q})
      when num <= 0 do
    new_queue = persist_state(q ++ [{description, func, arguments, client_schema}])
    {:reply, :ok, %{num_slots: 0, queue: new_queue}}
  end

  def handle_call({description, func, arguments, client_schema}, _, %{num_slots: num, queue: q})
      when num > 0 do
    pid = AppCount.Tasks.Runner.run_task(description, func, arguments, client_schema, :async)
    {:reply, pid, %{num_slots: num - 1, queue: q}}
  end

  def handle_call(:pop, _, %{
        num_slots: num,
        queue: [{description, func, arguments, client_schema} | rest]
      }) do
    pid = AppCount.Tasks.Runner.run_task(description, func, arguments, client_schema, :async)
    {:reply, pid, %{num_slots: num, queue: persist_state(rest)}}
  end

  def handle_call(:pop, _, %{num_slots: num, queue: []}) do
    {:reply, :ok, %{num_slots: Enum.min([num + 1, @max_tasks]), queue: persist_state([])}}
  end
end
