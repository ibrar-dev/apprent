defmodule AppCount.Support.FakeQueue do
  def enqueue(description, func, arguments, client_schema)
      when is_binary(description) and is_function(func) and is_list(arguments) and
             is_binary(client_schema) do
    case Process.whereis(:test_queue_listener) do
      nil -> nil
      pid -> Process.send(pid, {description, func, arguments, client_schema}, [:noconnect])
    end
  end

  def num_slots, do: 5
  def queue, do: []
  def pop, do: :ok

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
