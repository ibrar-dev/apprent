defmodule AppCount.Core.ConfigLoader do
  @moduledoc """
  Load values from the config.exs and environment specific files.
  example:
  some_setting = AppCount.Core.ConfigLoader.load().name_of_setting
  """
  defmacro __using__(_arg) do
    quote do
      def load() do
        Application.get_env(:app_count, __MODULE__, [])
        |> new()
      end

      def new(attrs) when is_list(attrs) do
        struct(__MODULE__, attrs)
      end
    end
  end
end
