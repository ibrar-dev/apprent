defmodule AppCount.Tasks.Worker do
  @moduledoc """
    Implements a scheduled task:

    defmodule SomeTask
      use AppCount.Tasks.Worker, "describes what this worker is doing"

      def perform() do
        [so scheduled stuff here]
      end
    end

    Simply using this module will add the worker to the frontend at https://[domain]/jobs
    where you can set up the schedule through the frontend

    Workers must define a `perform` function which will be the function that runs on the chosen schedule

  """
  @callback desc() :: String.t()
  @callback perform() :: any

  defmacro __using__(description) do
    quote do
      @behaviour AppCount.Tasks.Worker
      def __is_app_count_worker__(), do: true

      def desc() do
        unquote(description)
      end
    end
  end
end
