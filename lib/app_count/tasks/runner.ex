defmodule AppCount.Tasks.Runner do
  alias AppCount.Jobs

  def run_task(description, func, arguments, client_schema, :async)
      when is_binary(description) and is_binary(client_schema) and is_function(func) and
             is_list(arguments) do
    {:ok, pid} = start_link(description, arguments, client_schema)
    GenServer.cast(pid, {func, arguments})
    pid
  end

  # Note: currently only used in testing may be of use in prod in the future
  def run_task(description, func, arguments, client_schema)
      when is_binary(description) and is_binary(client_schema) and is_function(func) and
             is_list(arguments) do
    {:ok, pid} = start_link(description, arguments, client_schema)
    GenServer.call(pid, {func, arguments}, :infinity)
    pid
  end

  def start_link(description, arguments, client_schema) do
    GenServer.start(__MODULE__, [description, arguments, client_schema])
  end

  def init([description, arguments, client_schema]) do
    {
      :ok,
      %{
        logs: [],
        arguments: arguments,
        description: description,
        client_schema: client_schema,
        start_time: AppCount.current_time()
      }
    }
  end

  def handle_call({func, arguments}, _, state) do
    {:reply, do_run(func, arguments), state}
  end

  def handle_cast({func, arguments}, state) do
    do_run(func, arguments)
    {:noreply, state}
  end

  def handle_info({:log, message}, state) do
    {:noreply, Map.put(state, :logs, Enum.concat(state.logs, [message]))}
  end

  def handle_info({:flush, :error, message}, state) do
    state
    |> Map.merge(%{end_time: AppCount.current_time(), error: message, success: false})
    |> Jobs.insert_task(state.client_schema)

    {:stop, :normal, message}
  end

  def handle_info(:flush, state) do
    state
    |> Map.merge(%{end_time: AppCount.current_time(), success: true})
    |> Jobs.insert_task(state.client_schema)

    {:stop, :normal, nil}
  end

  # workaround for possible bug in hackney, see https://github.com/benoitc/hackney/issues/464
  # should remove when this PR: https://github.com/benoitc/hackney/pull/640 is released
  def handle_info(_, state), do: {:noreply, state}

  def do_run(func, arguments) do
    try do
      apply(func, arguments)
      Process.send(self(), :flush, [:noconnect])
      true
    rescue
      e in Protocol.UndefinedError ->
        handle_error("protocol #{inspect(e.protocol)} not implemented for #{inspect(e.value)}")

      e in FunctionClauseError ->
        handle_error("No function clause matching: #{e.module}.#{e.function}/#{e.arity}")

      e in BadArityError ->
        handle_error("Bad arity error: #{inspect(e.function)}: #{inspect(e.args)}")

      e ->
        handle_error("#{inspect(e.__struct__)}: #{Map.get(e, :message, inspect(e))}")
    after
      AppCount.Tasks.Queue.pop()
    end
  end

  defp handle_error(description) do
    Process.send(self(), {:flush, :error, description}, [:noconnect])
    false
  end
end
