defmodule AppCount.Support.InlineTask do
  @moduledoc """
  Use this stub to isolate tested behavior to a single process
  and run the function in the same task.
  """
  def start(module, function_name, args) do
    apply(module, function_name, args)
  end

  def start(fun) do
    fun.()
  end
end
