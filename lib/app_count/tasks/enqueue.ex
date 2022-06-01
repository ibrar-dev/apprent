defmodule AppCount.Tasks.Enqueue do
  @queue Application.compile_env(:app_count, :queue, AppCount.Tasks.Queue)

  def enqueue(description, func, arguments, client_schema)
      when is_binary(description) and is_function(func) and is_list(arguments) and
             is_binary(client_schema) do
    @queue.enqueue(description, func, arguments, client_schema)
  end

  def num_slots, do: @queue.num_slots()
  def queue, do: @queue.queue()
  def pop, do: @queue.pop()
end
