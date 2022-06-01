defmodule AppCount.Core.Tasker do
  @task AppCount.adapters(:tasker, Task)

  def start(module, function_name, args) do
    @task.start(module, function_name, args)
  end

  def start(fun) do
    @task.start(fun)
  end
end
