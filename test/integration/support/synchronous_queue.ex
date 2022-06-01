defmodule AppCount.Support.SynchronousQueue do
  def enqueue(description, func, arguments, client_schema)
      when is_binary(description) and is_function(func) and is_list(arguments) and
             is_binary(client_schema) do
    {:reply, queued_task_pid, _} =
      AppCount.Tasks.Queue.handle_call(
        {description, func, arguments, client_schema},
        nil,
        %{num_slots: 5, queue: []}
      )

    case is_queue_being_monitored?() do
      nil ->
        nil

      listener_pid ->
        ref = Process.monitor(queued_task_pid)

        receive do
          {:DOWN, ^ref, :process, ^queued_task_pid, :normal} ->
            # send monitor task an arbitrary message to cause it to kill itself
            Process.send(listener_pid, :something, [:noconnect])
        end
    end
  end

  def num_slots, do: 5
  def queue, do: []
  def pop, do: :ok

  defp is_queue_being_monitored?() do
    Process.whereis(:test_queue_listener)
  end

  def monitor_queue do
    {pid, ref} =
      Process.spawn(
        fn ->
          receive do
            _ -> Process.exit(self(), :kill)
          end
        end,
        [:monitor]
      )

    Process.register(pid, :test_queue_listener)
    ref
  end
end
