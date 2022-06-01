defmodule AppCount.Support.Adapters.SkipTask do
  @moduledoc """
  Use this stub to isolate tested behavor to a single process
  """
  def start(module, function_name, args) do
    # skip task
    # because unit tests should not test multi-process behavior
    # in test you can ...
    # assert_receive  {:start, ^module, ^function_name, ^args}
    send(self(), {:start, module, function_name, args})
  end

  def start(_fun) do
    # skip task
    # try to convert these calls into: start(module, function_name, args)
    # then you can use `assert_receive` in the test
  end
end
